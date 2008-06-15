include YARD::Generators::Helpers::MethodHelper
include YARD::Generators::Helpers::UMLHelper

before_run :is_namespace?

def init
  sections 'header', '../deprecated', 
           '../docstring', 'attributes', 
           T('listing/summary', :scope => [:class, :instance], :visibility => :public)
end