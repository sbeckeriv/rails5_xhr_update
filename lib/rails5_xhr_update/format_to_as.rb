# frozen_string_literal: true

require 'parser'
require 'unparser'
require "pry"

# Provide the XHRToRails5 class.
module Rails5XHRUpdate
  # Convert uses of the format param method to use the rails 5 syntax.
  #
  # For example prior to rails 5 one might write:
  #
  #     get :images_path, format: :json, params: {limit: 10, sort: 'new'}
  #     get :images_path, params: {limit: 10, sort: 'new', format: :json}
  #
  # This class will convert that into:
  #
  #     get :images_path, params: { limit: 10, sort: 'new' }, as: :json
  #
  # Note: cant handle **params conversions
  class FormatToAs < Parser::TreeRewriter
    def on_send(node)
      return unless [:get, :post, :put, :patch, :delete, :head].include?(node.children[1])
      arguments = extract_and_validate_arguments(node)
      if arguments
        children  = add_xhr_node(arguments)
        replace(node.loc.expression, Rails5XHRUpdate.ast_to_string(
          node.updated(nil,[nil,node.children[1], node.children[2]]+ children)
        ))
      end
    rescue Exception
      puts "#{node.loc.expression} #{$!}"
    end

    private

    def add_xhr_node(arguments)
      children = []
      arguments.keys.sort.each do |argument|
        value = arguments[argument]
        unless value.nil? 
          pair = value

          if value.is_a?(Hash)
            c=[]
            value.keys.sort.each do |vv|

              vvv= value[vv]
              unless value.nil? 
                c.push Rails5XHRUpdate.ast_pair(vv, vvv) 
              end
            end

            has = Parser::AST::Node.new(:hash, c) 
            pair = Rails5XHRUpdate.ast_pair(argument, has) 
          else
            pair = Rails5XHRUpdate.ast_pair(argument, value) 
          end

          children << pair
        end
      end
      [Parser::AST::Node.new(:hash, children)]
    end

    def extract_and_validate_arguments(node)
      arguments = node.children[3..-1]
      return nil unless arguments[0]
      if arguments[0].type == :hash
        # dont process if we have an as
        return nil if arguments[0].children[0].to_a.select{|c| c.children[0] == :as}.first
        result = {}
        arguments[0].children.each do |arg_node|
          raise Exception, "unexpected #{arg_node}" if arg_node.children.size != 2
          result[arg_node.children[0].children[0]] = arg_node.children[1]
        end
        if format = result.delete(:format)
          result[:as] = format
        end
        if params = result[:params]
          result_params = {}
          # if params is an ivar
          return nil unless params.respond_to?(:children)
          params.children.each do |param_node|
          return nil unless param_node.respond_to?(:children)
            raise Exception, "unexpected #{param_node}" if param_node.children.size != 2
            result_params[param_node.children[0].children[0]] = param_node.children[1]
          end
          if  format = result_params.delete(:format)
            result[:as] = format
          end
          result[:params] =result_params
        end
        result
      end
    end
  end
end
