#!/usr/bin/env ruby
require 'cgi'
require 'rubygems'
require "nokogiri"
require 'open-uri'
require 'uri'
require 'feta/query'

# ?query=/feature[actor[person/email='dmacvicar@novell.com' and role='infoprovider']]

module Feta
  #
  #
  # Small DSL into fate features
  #
  # Some examples:
  # Feature.query.only_actor(x).with_role.each do {|feature| ... }
  #
  # Features responds to the following issue methods, shared with
  # bugs:
  # id, title, url
  #
  class Feature

    attr_accessor :feature_id, :title, :products, :developers, :infoprovider

    attr_accessor :product_contexts

    class ProductContext
      attr_accessor :product, :status
    end

    def id
      feature_id
    end

    def initialize(client)
      @client = client
      @product_contexts = []
    end

    def self.find(what=nil)
      return Query.new.with_id(what).each.to_a.first if what
      Query.new
    end

    def self.query
      Query.new
    end

    def feature_url
      "#{@client.url}/#{id}"
    end

    def product
      return ""
    end

  end

end # module feta
