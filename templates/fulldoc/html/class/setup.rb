before_section :inheritance, :has_inheritance_tree?

def init
  sections 'header', ['inheritance', 'constructor']
end

def has_inheritance_tree?
  return false unless object.is_a?(YARD::CodeObjects::ClassObject)
  object.inheritance_tree.size > 1
end