require 'dynested/form_builder_helpers'
module Dynested
  class Railtie < Rails::Railtie
    initializer 'dynested.form_builder_helpers' do
      ActionView::Helpers::FormBuilder.send :include, FormBuilderHelpers
    end
  end
end
