before_section  :summary,   :has_methods?
before_section  :inherited, :has_inherited_methods?
before_section  :included,  :has_included_methods?

def init
  sections 'header', 'summary'
end