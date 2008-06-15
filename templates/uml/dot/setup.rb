before_section :dependencies, :show_dependencies?

def init
  options.visibility ||= :public
  options.full ||= true
  options.dependencies ||= false

  @objects = {}
  process_objects(object || YARD::Registry.root)
  @objects = @objects.values

  sections :header, [ 
    :unknown, [:unresolved, [:unknown_child]],
    :subgraph,
    :superclasses,
    :dependencies
  ]
end

def header(&block)
  tidy render(:header, &block)
end

def subgraph(&block)
  render(_subgraph(object), &block)
end

def unresolved(&block)
  @objects.select {|o| o.is_a?(YARD::CodeObjects::Proxy) }.map {|o| yieldall :object => o }.join("\n")
end

protected

def show_full_info?;    options.has_key? :full end
def show_dependencies?; options.has_key? :dependencies end

def _subgraph(obj) namespaces(obj).empty? ? :child : :subgraph end

def namespaces(obj)
  obj.children.select {|o| o.is_a?(YARD::CodeObjects::NamespaceObject) }
end

def unresolved_objects
  @direction_paths.values.flatten.select {|o| o.is_a?(YARD::CodeObjects::Proxy) }.uniq
end

def format_path(obj)
  obj.path.gsub('::', '_')
end

def h(text)
  text.to_s.gsub(/(\W)/, '\\\\\1')
end

def process_objects(obj)
  @objects[obj.path] = obj
  @objects[obj.superclass.path] = obj.superclass if obj.is_a?(YARD::CodeObjects::ClassObject)
  obj.mixins.each {|o| @objects[o.path] = o }
  
  namespaces(obj).each {|o| process_objects(o) }
end

def method_list(obj)
  vissort = lambda {|vis| vis == :public ? 'a' : (vis == :protected ? 'b' : 'c') }
  
  obj.meths(:inherited => false, :included => false, :visibility => options[:visibility]).reject do |o|
    o.is_attribute?
  end.sort_by {|o| "#{o.scope}#{vissort.call(o.visibility)}#{o.name}" }
end

private

def tidy(data)
  indent = 0
  data.split(/\n/).map do |line|
    line.gsub!(/^\s*/, '')
    next if line.empty?
    indent -= 1 if line =~ /^\s*\}\s*$/
    line = (' ' * (indent * 2)) + line
    indent += 1 if line =~ /\{\s*$/
    line
  end.compact.join("\n") + "\n"
end