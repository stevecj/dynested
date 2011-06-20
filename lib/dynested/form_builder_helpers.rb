module Dynested
  module FormBuilderHelpers
    def fields_for_collection(*args, &b)
      fields_for(*args, &b)
    end
  end
end
