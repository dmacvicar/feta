#--
# Copyright (c) 2011 SUSE LINUX Products GmbH
#
# Author: Duncan Mac-Vicar P. <dmacvicar@suse.de>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
require 'rest_client'
require 'nokogiri'
require 'feta/logging'

module Feta

  module Plugins
  end

  class Client

    include ::Feta::Logging

    KEEPER_XML_NS = "http://inttools.suse.de/sxkeeper/schema/keeper"

    attr_accessor :url

    # Construct a FATE client
    #
    # @param url [String, URI] URL of the FATE server
    #
    # @note Keeper behind iChain is not yet supported
    #
    def initialize(url)
      RestClient.log = Feta::Logging.logger
      url = URI.parse(url) if not url.is_a?(URI)
      @url = url.clone
      @headers = Hash.new

      # Scan plugins
      plugin_glob = File.join(File.dirname(__FILE__), 'plugins', '*.rb')
      Dir.glob(plugin_glob).each do |plugin|
        logger.debug("Loading file: #{plugin}")
        load plugin
      end

      #instantiate plugins
      ::Feta::Plugins.constants.each do |cnt|
        pl_class = ::Feta::Plugins.const_get(cnt)
        pl_instance = pl_class.new
        logger.debug("Loaded: #{pl_instance}")
        pl_instance.initialize_hook(url, logger, @headers)
      end

      @keeper_url = url
    end

    # Search for features
    #
    # @param query [Query] Query specifying the search criteria
    # @return [Array<Feature>] List of features
    def search(query)
      url_query = "?query=#{CGI.escape(query.to_xquery)}"
      url = URI.parse("#{@keeper_url}/feature#{url_query}").to_s

      xml = RestClient.get(url, @headers).body
      features = []
      doc = Nokogiri::XML(xml)
      doc.xpath('//feature', 'k' => KEEPER_XML_NS).each do |feat_element|
        feature = Feature.new(self)
        feature.feature_id = feat_element.xpath('./@k:id', 'k' => KEEPER_XML_NS).first.value
        feature.title = feat_element.xpath('./title', 'k' => KEEPER_XML_NS).first.content
        feat_element.xpath('./actor', 'k' => KEEPER_XML_NS).each do |actor|
          if actor.xpath('./role', 'k' => KEEPER_XML_NS).first.content == "infoprovider"
            feature.infoprovider = actor.xpath('.//email', 'k' => KEEPER_XML_NS).first.content
          end
        end
        yield feature if block_given?
        features << feature
      end
      features
    end

  end

end
