module Dynested
  module FormBuilderHelpers

    # An extended version of fields_for with improved support
    # for dynamic collections.  So far, this only supports a
    # collection name as the first argument, and does not yet
    # deal with having a model instance or array as the second
    # argument.
    def fields_for_collection(collection_name_or_array, *args, &b)
      options = args.extract_options!
      # Only handling the case of a lone collection name parameter for now.
      array = object.send(collection_name_or_array)
      view_context = eval("self", b)
      array.map do |item_object|
        item_name = nil
        ff = fields_for(collection_name_or_array, item_object, options) do |item_fields|
          item_name = item_fields.object_name
          b.call(item_fields)
        end
        collection_name = item_name.sub(/\[\d*\]$/,'')
        item_id = item_name.gsub('[','_').gsub(']','')
        view_context.content_tag(
          :div, ff,
          :class => 'nested_item',
          :id => item_id,
          'data-nested-collection' => collection_name,
          'data-nested-item' => item_name)
      end.inject {|result, item_output| result += item_output }
    end
  end
end
