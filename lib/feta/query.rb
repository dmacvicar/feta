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
require 'feta/common_client'

module Feta

  class Query

    include Enumerable

    def initialize
      @products = []
      @actor = nil
      @role = nil
      @feature_id = nil
    end

    # Queries only features where this actor is present
    # @param actor [String] Actor email
    def only_actor(actor)
      @actor = actor
      self
    end

    # Restrict the actor's role to +role+
    # @param role [String] Actor's role
    def with_role(role)
      @role = role
      self
    end

    # Queries only features for these product
    # @param product [String] Product name
    def only_product(product)
      only_products([product])
    end

    # Queries only features for these products
    # @param products [Array<String>] Product name list
    def only_products(products)
      @products = []
      @products = products.flatten
      self
    end

    def with_id(id)
      @feature_id = id
      self
    end

    # Converts the query to an xpath expression
    # @return [String] xpath expression representing the query
    # @private
    def to_xquery
      id_query = @feature_id ? "@k:id=#{@feature_id}" : ""
      role_query = @role ? " and role='#{@role}'" : ""
      actor_query = @actor ? "actor[person/email='#{@actor}'#{role_query}]" : ""
      prods = @products.collect {|p| "product/name='#{p}'"}.join(" or ")
      product_query = (!@products.empty?) ? "productcontext[#{prods}]" : ""
      conditions = [id_query, actor_query, product_query].reject{ |x| x.empty? }.join(' and ')
      query = "/feature[#{conditions}]"
    end

    # Iterates through the result of the current query.
    #
    # @note Requires Feta.client to be set
    #
    # @yield [Feta::Feature]
    def each
      ret = Feta.client.search(self)
      return ret.each if not block_given?
      ret.each { |feature| yield feature }
    end

  end

end
