module Dynested
  class JavascriptGenerator < Rails::Generators::Base
    desc "Add the dynested.js file to the rails application."
    source_root File.expand_path('../../templates', __FILE__)

    def add_javascript
      copy_file 'dynested.js', 'public/javascripts/dynested.js'
    end
  end
end
