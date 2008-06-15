inherits '../../../ri/text/method'

before_section :aliases, :has_aliases?

def init
  sections 'header', [
    'title', ['signature', 'aliases'],
    'deprecated', 'docstring', 'tags', 'source'
  ]
end

protected

def has_aliases?
  !object.aliases.empty?
end