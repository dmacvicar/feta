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

    # A feature different statuses and other properties with regard
    # to different products
    #
    # @return [Hash] key is the product, value is a {ProductContext}
    attr_accessor :product_contexts

    class ProductContext

      def initialize
        @priorities = Hash.new
      end

      # Status of the feature for a specific product
      # (+:evaluation+, +:implementation+, etc)
      attr_accessor :status

      # If status is +:evaluation+ then the status has a owner
      # (+:teamleader+, +:projectmanager+, etc)
      attr_accessor :status_owner

      # For an specific product, a feature has
      # @return [Hash] key is the owner, value is the priority
      attr_accessor :priorities
    end

    def id
      feature_id
    end

    def initialize(client)
      @client = client
      @product_contexts = Hash.new
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

    # @param product [String] Product name
    # @return [Symbol] status for +product+ or nil
    #   if the product is not in the feature
    def status_for_product(product)
      ctx{product.to_s}.status
    end

    # @return [Symbol] the priority of this feature
    #   given by +role+ for +product+
    def priority_for_product_and_role(product, role)
      product_contexts{product.to_s}.priorities[role.to_sym]
    end

  end

end # module feta
