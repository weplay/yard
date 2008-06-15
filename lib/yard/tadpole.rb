require 'rubygems'
require 'tadpole'

Tadpole.register_template_path(YARD::TEMPLATE_ROOT)
Tadpole::Template.send(:include, YARD::Generators::Helpers::BaseHelper)
Tadpole::Template.send(:include, YARD::Generators::Helpers::FilterHelper)

module Tadpole::LocalTemplate
  before_run :set_options
  before_run :run_verifier
  
  protected
  
  def run_verifier
    return verifier.call(self, object) if verifier
  end
  
  def set_options
    options.serializer ||= nil
    options.verifier   ||= nil
  end
end