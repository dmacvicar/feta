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

    # Defines the equality of two features (same id)
    # @param [Feature] other_feature Feature to compare with
    def ==(other_feature)
      self.id == other_feature.id
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
    # @return [Symbol] status for +product+ or +nil+
    #   if the product is not in the feature
    def status_for_product(product)
      product_contexts[product.to_s].status rescue :nil
    end

    # @return [Symbol] the priority of this feature
    #   given by +role+ for +product+ or +nil+ if the product
    #   is not in the feature
    def priority_for_product_and_role(product, role)
      product_contexts[product.to_s].priorities[role.to_sym] rescue :nil
    end

    # @return [Fixnum] numeric priority for this feature
    #   use it for sorting
    def numeric_priority_for_product_and_role(product, role)
      case priority_for_product_and_role(product, role)
        when :neutral then 0
        when :desirable then 1
        when :important then 2
        when :mandatory then 3
        else -1
      end
    end

  end

end # module feta
