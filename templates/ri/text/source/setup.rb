include YARD::Generators::Helpers::MethodHelper

before_run :has_source?

def init
  sections 'main'
end

protected

def has_source?
  object.source ? true : false
end