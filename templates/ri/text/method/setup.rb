include YARD::Generators::Helpers::MethodHelper

before_run :is_method?

def init
  sections 'header', 'deprecated', 'docstring', 'signature', 'tags', 'source'
end