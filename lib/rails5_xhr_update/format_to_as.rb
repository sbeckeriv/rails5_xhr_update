# frozen_string_literal: true

require 'parser'
require 'unparser'
require "pry"

# Provide the XHRToRails5 class.
module Rails5XHRUpdate
  AST_TRUE = Parser::AST::Node.new(:true) # rubocop:disable Lint/BooleanSymbol)

  # Convert uses of the xhr method to use the rails 5 syntax.
  #
  # For example prior to rails 5 one might write:
  #
  #     xhr :get, images_path, limit: 10, sort: 'new'
  #
  # This class will convert that into:
  #
  #     get images_path, params: { limit: 10, sort: 'new' }, xhr: true
  class FormatToAs < Parser::TreeRewriter
    def on_send(node)
      return unless [:get, :post, :put, :update, :delete].include?(node.children[1])
      arguments = extract_and_validate_arguments(node)
      if arguments
        children  = add_xhr_node(arguments)
        replace(node.loc.expression, Rails5XHRUpdate.ast_to_string(
          node.updated(nil,[nil,node.children[1], node.children[2]]+ children)
        ))
      end
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
      if arguments[0].type == :hash
        # dont process if we have an as
        return nil if arguments[0].children[0].to_a.select{|c| c.children[0] == :as}.first
        result = {}
        arguments[0].children.each do |node|
          raise Exception, "unexpected #{node}" if node.children.size != 2
          result[node.children[0].children[0]] = node.children[1]
        end
        if format = result.delete(:format)
          result[:as] = format
        end
        if params = result[:params]
          result_params = {}
          params.children.each do |node|
            raise Exception, "unexpected #{node}" if node.children.size != 2
            result_params[node.children[0].children[0]] = node.children[1]
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
