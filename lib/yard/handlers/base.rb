module YARD
  module Handlers
    class NamespaceMissingError < Parser::UndocumentableError
      attr_accessor :object
      def initialize(object) @object = object end
    end
    
    # = Handlers 
    # 
    # Handlers are pluggable semantic parsers for YARD's code generation 
    # phase. They allow developers to control what information gets 
    # generated by YARD, giving them the ability to, for instance, document
    # any Ruby DSLs that a customized framework may use. A good example
    # of this would be the ability to document and generate meta data for
    # the 'describe' declaration of the RSpec testing framework by simply
    # adding a handler for such a keyword. Similarly, any Ruby API that
    # takes advantage of class level declarations could add these to the
    # documentation in a very explicit format by treating them as first-
    # class objects in any outputted documentation.
    # 
    # == Overview of a Typical Handler Scenario 
    # 
    # Generally, a handler class will declare a set of statements which
    # it will handle using the {handles} class declaration. It will then
    # implement the {#process} method to do the work. The processing would
    # usually involve the manipulation of the {#namespace}, {#owner} 
    # {CodeObjects::Base code objects} or the creation of new ones, in 
    # which case they should be registered by {#register}, a method that 
    # sets some basic attributes for the new objects.
    # 
    # Handlers are usually simple and take up to a page of code to process
    # and register a new object or add new attributes to the current +namespace+.
    # 
    # == Setting up a Handler for Use 
    # 
    # A Handler is automatically registered when it is subclassed from the
    # base class. The only other thing that needs to be done is to specify
    # which statement the handler will process. This is done with the +handles+
    # declaration, taking either a {Parser::Ruby::Legacy::RubyToken}, {String} or `Regexp`.
    # Here is a simple example which processes module statements.
    # 
    #   class MyModuleHandler < YARD::Handlers::Base
    #     handles TkMODULE
    # 
    #     def process
    #       # do something
    #     end
    #   end
    # 
    # == Processing Handler Data 
    # 
    # The goal of a specific handler is really up to the developer, and as 
    # such there is no real guideline on how to process the data. However,
    # it is important to know where the data is coming from to be able to use
    # it.
    # 
    # === +statement+ Attribute 
    # 
    # The +statement+ attribute pertains to the {Parser::Ruby::Legacy::Statement} object
    # containing a set of tokens parsed in by the parser. This is the main set
    # of data to be analyzed and processed. The comments attached to the statement
    # can be accessed by the {Parser::Ruby::Legacy::Statement#comments} method, but generally
    # the data to be processed will live in the +tokens+ attribute. This list
    # can be converted to a +String+ using +#to_s+ to parse the data with
    # regular expressions (or other text processing mechanisms), if needed.
    # 
    # === +namespace+ Attribute 
    # 
    # The +namespace+ attribute is a {CodeObjects::NamespaceObject namespace object} 
    # which represents the current namespace that the parser is in. For instance:
    # 
    #   module SomeModule
    #     class MyClass
    #       def mymethod; end
    #     end
    #   end
    # 
    # If a handler was to parse the 'class MyClass' statement, it would
    # be necessary to know that it belonged inside the SomeModule module.
    # This is the value that +namespace+ would return when processing such
    # a statement. If the class was then entered and another handler was
    # called on the method, the +namespace+ would be set to the 'MyClass'
    # code object.
    # 
    # === +owner+ Attribute 
    # 
    # The +owner+ attribute is similar to the +namespace+ attribute in that
    # it also follows the scope of the code during parsing. However, a namespace
    # object is loosely defined as a module or class and YARD has the ability
    # to parse beyond module and class blocks (inside methods, for instance),
    # so the +owner+ attribute would not be limited to modules and classes. 
    # 
    # To put this into context, the example from above will be used. If a method
    # handler was added to the mix and decided to parse inside the method body,
    # the +owner+ would be set to the method object but the namespace would remain
    # set to the class. This would allow the developer to process any method
    # definitions set inside a method (def x; def y; 2 end end) by adding them
    # to the correct namespace (the class, not the method).
    # 
    # In summary, the distinction between +namespace+ and +owner+ can be thought
    # of as the difference between first-class Ruby objects (namespaces) and
    # second-class Ruby objects (methods).
    # 
    # === +visibility+ and +scope+ Attributes 
    # 
    # Mainly needed for parsing methods, the +visibility+ and +scope+ attributes
    # refer to the public/protected/private and class/instance values (respectively)
    # of the current parsing position.
    # 
    # == Parsing Blocks in Statements 
    # 
    # In addition to parsing a statement and creating new objects, some
    # handlers may wish to continue parsing the code inside the statement's
    # block (if there is one). In this context, a block means the inside
    # of any statement, be it class definition, module definition, if
    # statement or classic 'Ruby block'. 
    # 
    # For example, a class statement would be "class MyClass" and the block 
    # would be a list of statements including the method definitions inside 
    # the class. For a class handler, the programmer would execute the 
    # {#parse_block} method to continue parsing code inside the block, with 
    # the +namespace+ now pointing to the class object the handler created. 
    # 
    # YARD has the ability to continue into any block: class, module, method, 
    # even if statements. For this reason, the block parsing method must be 
    # invoked explicitly out of efficiency sake.
    # 
    # @see CodeObjects::Base
    # @see CodeObjects::NamespaceObject
    # @see handles
    # @see #namespace
    # @see #owner
    # @see #register
    # @see #parse_block
    #
    class Base 
      # For accessing convenience, eg. "MethodObject" 
      # instead of the full qualified namespace
      include YARD::CodeObjects
      
      include Parser
      
      class << self
        def clear_subclasses
          @@subclasses = []
        end
        
        def subclasses
          @@subclasses ||= []
        end

        def inherited(subclass)
          @@subclasses ||= []
          @@subclasses << subclass
        end

        # Declares the statement type which will be processed
        # by this handler. 
        # 
        # A match need not be unique to a handler. Multiple
        # handlers can process the same statement. However,
        # in this case, care should be taken to make sure that
        # {#parse_block} would only be executed by one of
        # the handlers, otherwise the same code will be parsed
        # multiple times and slow YARD down.
        # 
        # @param [Parser::RubyToken, Symbol, String, Regexp] matches
        #   statements that match the declaration will be
        #   processed by this handler. A {String} match is 
        #   equivalent to a +/\Astring/+ regular expression 
        #   (match from the beginning of the line), and all 
        #   token matches match only the first token of the
        #   statement.
        # 
        def handles(*matches)
          (@handlers ||= []).push(*matches)
        end
        
        def handles?(statement)
          raise NotImplementedError, "override #handles? in a subclass"
        end
        
        def handlers
          @handlers ||= []
        end
        
        def namespace_only
          @namespace_only = true
        end
        
        def namespace_only?
          @namespace_only ? true : false
        end
      end

      def initialize(source_parser, stmt)
        @parser = source_parser
        @statement = stmt
      end

      # The main handler method called by the parser on a statement
      # that matches the {handles} declaration.
      # 
      # Subclasses should override this method to provide the handling
      # functionality for the class. 
      # 
      # @return [Array<CodeObjects::Base>, CodeObjects::Base, Object]
      #   If this method returns a code object (or a list of them),
      #   they are passed to the +#register+ method which adds basic
      #   attributes. It is not necessary to return any objects and in
      #   some cases you may want to explicitly avoid the returning of
      #   any objects for post-processing by the register method.
      # 
      # @see handles
      # @see #register
      # 
      def process
        raise NotImplementedError, "#{self} did not implement a #process method for handling."
      end
      
      def parse_block(*args)
        raise NotImplementedError, "#{self} did not implement a #parse_block method for handling"
      end
      
      protected
      
      attr_reader :parser, :statement
      attr_accessor :owner, :namespace, :visibility, :scope
      
      def owner; parser.owner end
      def owner=(v) parser.owner=(v) end
      def namespace; parser.namespace end
      def namespace=(v); parser.namespace=(v) end
      def visibility; parser.visibility end
      def visibility=(v); parser.visibility=(v) end
      def scope; parser.scope end
      def scope=(v); parser.scope=(v) end
      
      def push_state(opts = {}, &block)
        opts = {
          :namespace => nil,
          :scope => :instance,
          :owner => nil
        }.update(opts)

        if opts[:namespace]
          ns, vis, sc = namespace, visibility, scope
          self.namespace = opts[:namespace]
          self.visibility = :public
          self.scope = opts[:scope]
        end

        oldowner, self.owner = self.owner, opts[:owner] ? opts[:owner] : namespace
        yield
        self.owner = oldowner

        if opts[:namespace]
          self.namespace = ns
          self.owner = namespace
          self.visibility = vis
          self.scope = sc
        end
      end
      
      # Do some post processing on a list of code objects. 
      # Adds basic attributes to the list of objects like 
      # the filename, line number, {CodeObjects::Base#dynamic},
      # source code and {CodeObjects::Base#docstring},
      # but only if they don't exist.
      # 
      # @param [Array<CodeObjects::Base>] objects
      #   the list of objects to post-process.
      # 
      # @return [CodeObjects::Base, Array<CodeObjects::Base>]
      #   returns whatever is passed in, for chainability.
      # 
      def register(*objects)
        objects.flatten.each do |object|
          next unless object.is_a?(CodeObjects::Base)
          
          begin
            ensure_loaded!(object.namespace)
            object.namespace.children << object
          rescue NamespaceMissingError
          end
          
          # Yield the object to the calling block because ruby will parse the syntax
          #   
          #     register obj = ClassObject.new {|o| ... }
          # 
          # as the block for #register. We need to make sure this gets to the object.
          yield(object) if block_given? 
          
          object.add_file(parser.file, statement.line, statement.comments)

          # Add docstring if there is one.
          object.docstring = statement.comments if statement.comments
          object.docstring.line_range = statement.comments_range
          
          # Add source only to non-class non-module objects
          unless object.is_a?(NamespaceObject)
            object.source ||= statement
          end
          
          # Make it dynamic if its owner is not its namespace.
          # This generally means it was defined in a method (or block of some sort)
          object.dynamic = true if owner != namespace
        end
        objects.size == 1 ? objects.first : objects
      end

      def ensure_loaded!(object, max_retries = 1)
        return if object == Registry.root
        unless parser.load_order_errors
          if object.is_a?(Proxy)
            raise NamespaceMissingError, object
          else
            nil
          end
        end
        
        if !defined?(callcc)
          log.warn "This ruby implementation does not implement Kernel#callcc and cannot load files in order. You must specify the correct order manually."
          raise NamespaceMissingError, object
        end
        
        retries = 0
        context = callcc {|c| c }
        retries += 1 
        
        if object.is_a?(Proxy)
          if retries <= max_retries
            log.debug "Missing object #{object} in file `#{parser.file}', moving it to the back of the line."
            raise Parser::LoadOrderError, context
          else
            raise NamespaceMissingError, object
          end
        else
          log.debug "Object #{object} successfully resolved. Adding children."
        end
        object
      end
    end
  end
end