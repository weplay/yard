require 'cgi'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module YARD
  module Generators::Helpers
    module HtmlHelper
      SimpleMarkup = SM::SimpleMarkup.new
      SimpleMarkupHtml = SM::ToHtml.new
    
      def h(text)
        CGI.escapeHTML(text.to_s)
      end
    
      def urlencode(text)
        CGI.escape(text.to_s)
      end

      def htmlify(text)
        html = resolve_links SimpleMarkup.convert(text, SimpleMarkupHtml)
        html = html.gsub(/<pre>(.+?)<\/pre>/m) { '<pre class="code">' + html_syntax_highlight(CGI.unescapeHTML($1)) + '</pre>' }
        html
      end

      def resolve_links(text)
        text.gsub(/(\s)\{(\S+?)(?:\s(.+?))?\}(?=(?:[\s\.,:!;\?][^<>]*)?<\/(?!pre))/) do 
          name = $2
          title = $3 || $2
          obj = P(object, name)
          if obj.is_a?(CodeObjects::Proxy)
            log.warn "In documentation for #{object.path}: Cannot resolve link to #{obj.path} from text:"
            log.warn '...' + text[/(.{0,20}\{#{Regexp.quote name}.*?\}.{0,20})/, 1].gsub(/\n/,"\n\t") + '...'
          end
          
          " <tt>" + linkify(obj, title) + "</tt>" 
        end
      end

      def format_object_name_list(objects)
        objects.sort_by {|o| o.name.to_s.downcase }.map do |o| 
          "<span class='name'>" + linkify(o, o.name) + "</span>" 
        end.join(", ")
      end
      
      # Formats a list of types from a tag.
      # 
      # @param [Array<String>, FalseClass] typelist
      #   the list of types to be formatted. 
      # 
      # @param [Boolean] brackets omits the surrounding 
      #   brackets if +brackets+ is set to +false+.
      # 
      # @return [String] the list of types formatted
      #   as [Type1, Type2, ...] with the types linked
      #   to their respective descriptions.
      # 
      def format_types(typelist, brackets = true)
        list = typelist.map do |type| 
          "<tt>" + type.gsub(/(^|[<>])\s*([^<>#]+)\s*(?=[<>]|$)/) {|m| h($1) + linkify($2, $2) } + "</tt>"
        end
        list.empty? ? "" : (brackets ? "[#{list.join(", ")}]" : list.join(", "))
      end
    
      def link_object(other, otitle = nil, anchor = nil)
        obj = P(object, other) if other.is_a?(String)
        title = h(otitle ? otitle.to_s : other.path)
        return title unless serializer

        return title if other.is_a?(CodeObjects::Proxy)
      
        link = url_for(other, anchor)
        link ? "<a href='#{link}' title='#{title}'>#{title}</a>" : title
      end
    
      def anchor_for(obj)
        urlencode case obj
        when CodeObjects::MethodObject
          "#{obj.name}-#{obj.scope}_#{obj.type}"
        when CodeObjects::Base
          "#{obj.name}-#{obj.type}"
        when CodeObjects::Proxy
          obj.path
        else
          obj.to_s
        end
      end
    
      def url_for(obj, anchor = nil, relative = true)
        link = nil
        return link unless serializer
        
        if obj.is_a?(CodeObjects::Base) && !obj.is_a?(CodeObjects::NamespaceObject)
          # If the object is not a namespace object make it the anchor.
          anchor, obj = obj, obj.namespace
        end
        
        objpath = serializer.serialized_path(obj)
        return link unless objpath
      
        if relative
          fromobj = object
          if object.is_a?(CodeObjects::Base) && 
              !object.is_a?(CodeObjects::NamespaceObject)
            fromobj = fromobj.namespace
          end

          from  = serializer.serialized_path(fromobj)
          link  = File.relative_path(from, objpath)
        else
          link = objpath
        end
      
        link + (anchor ? '#' + anchor_for(anchor) : '')
      end

      def html_syntax_highlight(source)
        tokenlist = Parser::TokenList.new(source)
        tokenlist.map do |s| 
          prettyclass = s.class.class_name.sub(/^Tk/, '').downcase
          prettysuper = s.class.superclass.class_name.sub(/^Tk/, '').downcase

          case s
          when Parser::RubyToken::TkWhitespace, Parser::RubyToken::TkUnknownChar
            h s.text
          when Parser::RubyToken::TkId
            prettyval = h(s.text)
            "<span class='#{prettyval} #{prettyclass} #{prettysuper}'>#{prettyval}</span>"
          else
            "<span class='#{prettyclass} #{prettysuper}'>#{h s.text}</span>"
          end
        end.join
      end
    end
  end
end
    
    