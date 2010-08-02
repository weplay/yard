# Handles the 'include' statement to mixin a module in the instance scope
class YARD::Handlers::Ruby::MixinHandler < YARD::Handlers::Ruby::Base
  namespace_only
  handles method_call(:include)
  
  process do
    statement.parameters(false).each {|mixin| process_mixin(mixin) }
  end

  protected

  def process_mixin(mixin)
    unless mixin.ref?
      raise YARD::Parser::UndocumentableError, "mixin #{mixin.source} for class #{namespace.path}"
    end
    
    case obj = Proxy.new(namespace, mixin.source)
    when Proxy
      obj.type = :module
    when ConstantObject # If a constant is included, use its value as the real object
      obj = Proxy.new(namespace, obj.value)
    end
    
    namespace.mixins(scope).unshift(obj) unless namespace.mixins(scope).include?(obj)
  end
end
