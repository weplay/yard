before_run :has_constructor?
 
def init
  sections 'main', ['../../method']
end

protected

def has_constructor?
  constructor_method ? true : false 
end

def constructor_method
  object.meths.find {|o| o.name == :initialize && o.scope == :instance }
end

def constructor_method_inherited?
  constructor_method.namespace != object
end