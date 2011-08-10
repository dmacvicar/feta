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
      [ File.join(ENV['HOME'], '.local/share/feta/plugins/*.rb'),
        File.join(File.dirname(__FILE__), 'plugins', '*.rb') ].each do |plugin_glob|
        Dir.glob(plugin_glob).each do |plugin|
          logger.debug("Loading file: #{plugin}")
          load plugin
        end
      end

      #instantiate plugins
      pl_instances = []
      ::Feta::Plugins.constants.each do |cnt|
        pl_class = ::Feta::Plugins.const_get(cnt)
        pl_instances << pl_class.new
      end

      pl_instances.sort{|x,y| x.order <=> y.order}.each do |pl_instance|
        logger.debug("Loaded: #{pl_instance}")
        pl_instance.initialize_hook(url, logger, @headers)
      end

      @keeper_url = url
    end

    # helper method to sort relation tree elements with subelements
    # @param element [Nokogiri::Element] Element to calculate its sorting order
    # @private
    def self.sorting_order(element)
      if element.parent.element? && element.parent.name == "relation"
          return (element.attributes['sortPosition'].to_s.to_f / 10) + sorting_order(element.parent)
      end
      return element.attributes['sortPosition'].to_s.to_f
    end

    def get_relation_tree(tree_name)
      url_query = CGI.escape("/relationtree[contains(title,'#{tree_name}')]")
      url = URI.parse("#{@keeper_url}/relationtree?query=#{url_query}").to_s
      xml = RestClient.get(url, @headers).body
      doc = Nokogiri::XML(xml)
      elements = []
      elements = doc.xpath('//relation', 'k' => KEEPER_XML_NS)

      # Make a flat list leaving only the more granular features
      # (not master features)
      ids = elements.collect { |x| x.ancestors.select {|x| x.element? && x.name == "relation" } }.flatten.uniq.collect { |x| x.attributes['target']}
      elements = elements.reject {|x| ids.include?(x.attributes['target'])}

      # Create a map with the sorting order by id
      order_map = Hash.new
      elements.each do |element|
        order_map[element.attributes['target'].to_s] = self.class.sorting_order(element)
      end

      # build the predicate querying all the features in the
      # relation tree
      predicate = order_map.keys.collect {|x| "@k:id=#{x}"}.join(" or ")
      xquery = "/feature[#{predicate}]"

      # do query and sort by relation tree
      search_by_xquery(xquery).sort {|x,y| order_map[x.id] <=> order_map[y.id]}
    end

    # Search for features
    #
    # @param query [Query] Query specifying the search criteria
    # @return [Array<Feature>] List of features
    def search(query)
      search_by_xquery(query.to_xquery)
    end

    def search_by_xquery(xquery)
      logger.debug "XQuery: #{xquery}"
      url = URI.parse("#{@keeper_url}/feature?query=#{CGI.escape(xquery)}").to_s
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
        feat_element.xpath('./productcontext', 'k' => KEEPER_XML_NS).each do |ctx_element|
          ctx = Feature::ProductContext.new
          product = ctx_element.xpath('./product/name').first.content
          ctx.status = ctx_element.xpath('./status').children.select {|x| x.element?}.first.name.to_sym
          feature.product_contexts[product] = ctx

          # Priorities
          ctx_element.xpath('./priority').each do |prio_element|
            prio = prio_element.children.select(&:element?).first.name.to_sym
            owner = prio_element.xpath('./owner/role').first.content.to_sym
            ctx.priorities[owner] = prio
          end
        end
        yield feature if block_given?
        features << feature
      end
      features
    end

  end

end
