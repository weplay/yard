before_run :is_deprecated?

def init
  sections 'main'
end

protected

def is_deprecated?
  object.tag(:deprecated) ? true : false
end