before_section :header, :has_tags?

def init
  sections 'header', [:param, :yieldparam, :return, :raises, :author, :version, :since, 'see']
end

def param
  render_tags :param
end

def yieldparam
  render_tags :yieldparam
end

def return
  render_tags :return
end

def raises
  render_tags :raise, :no_names => true
end

def author
  render_tags :author, :no_types => true, :no_names => true
end

def version
  render_tags :version, :no_types => true, :no_names => true
end

def since
  render_tags :since, :no_types => true, :no_names => true
end

protected

def has_tags?
  object.tags.size > 0
end

def render_tags(name, opts = {})
  opts = { :name => name }.update(opts)
  render('tags', opts)
end