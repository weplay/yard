require 'erb'
require 'tadpole'

module YARD
  module Generators
    class Base
      include Helpers::BaseHelper
      include Helpers::FilterHelper

      class << self
        ##
        # Registers a template path.
        # 
        # @param [String] path 
        #   the pathname to look for the template
        def register_template_path(path)
          Tadpole.register_template_path(path)
        end
        
        def before_list(meth)
          before_list_filters.push(meth)
        end
        
        def before_list_filters
          @before_list_filters ||= []
        end
      end
      
      # Creates a generator by adding extra options
      # to the options hash. 
      # 
      # @example [Creates a new MethodSummaryGenerator for public class methods]
      #   G(MethodSummaryGenerator, :scope => :class, :visibility => :public)
      # 
      # @param [Class] generator 
      #   the generator class to use.
      # 
      # @options opts
      #   :ignore_serializer -> true => value
      #
      # 
      def G(generator, opts = {})
        opts = SymbolHash[:ignore_serializer => true].update(opts)
        generator.new(options, opts)
      end

      attr_reader :format, :template, :verifier
      attr_reader :serializer, :ignore_serializer
      attr_reader :options
      attr_reader :current_object
      
      def initialize(opts = {}, extra_opts = {})
        opts = SymbolHash[
          :format => :html,
          :template => :default,
          :serializer => nil,
          :verifier => nil
        ].update(opts).update(extra_opts)
        
        @options = opts
        @format = options[:format]
        @template = options[:template] 
        @serializer = options[:serializer] 
        @ignore_serializer = options[:ignore_serializer]
        @verifier = options[:verifier]
        
        extend Helpers::HtmlHelper if format == :html
      end
      
      def generator_name
        self.class.to_s.split("::").last.gsub(/Generator$/, '').downcase
      end
      
      def generate(*list, &block)
        output = ""

        list = list.flatten
        @current_object = Registry.root
        return output if FalseClass === run_before_list(list)

        serializer.before_serialize if serializer && !ignore_serializer
        
        list.each do |object|
          next unless object && object.is_a?(CodeObjects::Base)
          
          objout = ""
          @current_object = object

          next if call_verifier(object).is_a?(FalseClass)
          
          objout << template_for(object).run(:object => object, &block) 

          if serializer && !ignore_serializer && !objout.empty?
            serializer.serialize(object, objout) 
          end
          output << objout
        end
        
        if serializer && !ignore_serializer
          serializer.after_serialize(output) 
        end
        output
      end
      
      protected
      
      def call_verifier(object)
        if verifier.is_a?(Symbol)
          send(verifier, object)
        elsif verifier.respond_to?(:call)
          verifier.call(self, object)
        end
      end
      
      def run_before_list(list)
        self.class.before_list_filters.each do |meth|
          meth = method(meth) if meth.is_a?(Symbol)
          result = meth.call *(meth.arity == 0 ? [] : [list])
          return result if result.is_a?(FalseClass)
        end
      end
      
      def template_for(object)
        Template(format, template).new(options)
      end
    end
  end
end
