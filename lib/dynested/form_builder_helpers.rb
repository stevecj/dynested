module Dynested
  module FormBuilderHelpers
    
    # An extended version of fields_for with improved support
    # for dynamic collections.  So far, this only supports a
    # collection name as the first argument, and does not yet
    # deal with having a model instance or array as the second
    # argument.
    def fields_for_collection(collection_name_or_array, *args, &b)
      opts = args.extract_options!
      # Only handling the case of a lone collection name parameter for now.
      array = object.send(collection_name_or_array)
      items = array.map do |item_object|
        item = FieldsForItem.new(self, collection_name_or_array, item_object, opts, &b)
        item.wrap_as_item_element
        item
      end
      new_obj_for_template = array.new
      template_item = FieldsForItem.new(self, collection_name_or_array, new_obj_for_template, opts, &b)
      template_item.wrap_as_item_element
      template_item.wrap_as_new_item_template
      items << template_item
      items.map(&:content).inject{|m, content| m += content}
    end

    class FieldsForItem
      attr_accessor :content

      def initialize(builder, collection_attr_name, item_object, opts={}, &b)
        @view_context = eval('self', b)

        # Invoke fields_for with supplied block, and capture
        # the item object name from the fields_for block
        # context.
        @content = builder.fields_for(
          collection_attr_name, item_object, opts
        ) do |item_fields|
          @item_name = item_fields.object_name
          b.call(item_fields)
        end

        @collection_name = @item_name.sub(/\[\d*\]$/, '')
      end

      def wrap_as_item_element
        element_id = @item_name.gsub('[', '_').gsub(']', '')
        @content = @view_context.content_tag(
          :div, @content,
          :class                   => 'nested_item',
          :id                      => element_id,
          'data-nested-collection' => @collection_name,
          'data-nested-item'       => @item_name
        )
      end

      def wrap_as_new_item_template
        @content = @view_context.content_tag(
          :div, @content,
          :class                   => 'nested_item_template',
          :style                   => 'display: none',
          'data-nested-collection' => @collection_name,
          'data-next-nested-item'  => @item_name
        )
      end
    end

  end
end
