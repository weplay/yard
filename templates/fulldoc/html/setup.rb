include YARD::Generators::Helpers::HtmlHelper

def setup_options
  super
  options.visibility ||= :public
end