before_run :has_docstring?

def init
  sections 'main'
end

protected

def has_docstring?
  !object.docstring.empty?
end