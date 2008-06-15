module YARD
  module Generators
    class UMLGenerator < Base
      def template_for(object)
        Template('uml/dot')
      end
    end
  end
end