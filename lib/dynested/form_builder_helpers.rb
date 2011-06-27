module Dynested
  module FormBuilderHelpers
    NEWLINE = "\n".html_safe()
    
    # An extended version of fields_for with improved support
    # for dynamic collections.  So far, this only supports a
    # collection name as the first argument, and does not yet
    # deal with having a model instance or array as the second
    # argument.
    def fields_for_collection(collection_name_or_array, *args, &b)
      opts = args.extract_options!
      with_new_item = opts.delete(:new_item)

      # Only handling the case of a lone collection name parameter for now.
      array = object.send(collection_name_or_array)
      item_objects = Array.new(array)
      item_objects << array.build if with_new_item
      items = item_objects.map do |item_object|
        item = FieldsForItem.new(self, collection_name_or_array, item_object, opts, &b)
        item.wrap_as_item_element
        item
      end
      new_obj_for_template = array.build
      template_item = FieldsForItem.new(self, collection_name_or_array, new_obj_for_template, opts, &b)
      template_item.wrap_as_item_element
      template_item.wrap_as_new_item_template
      items << template_item
      items.map(&:content).inject{|m, content| m += (content + NEWLINE) }
    end

    def link_to_add_collection_item(collection_attr_name, html_options={}, &b)
      view_context = eval('self', b.binding)
      collection_name = '%s[%s_attributes]' % [object_name, collection_attr_name]
      html_options = HashWithIndifferentAccess.new(html_options)
      html_options[:class] = 'new_nested_item_link'
      html_options['data-nested-collection'] = collection_name
      view_context.link_to('JavaScript:void(0);', html_options, &b)
    end

    class FieldsForItem
      attr_accessor :content

      def initialize(builder, collection_attr_name, item_object, opts={}, &b)
        @view_context = eval('self', b.binding)

        # Invoke fields_for with supplied block, and capture
        # the item object name from the fields_for block
        # context.
        @content = builder.fields_for(
          collection_attr_name, item_object, opts
        ) do |item_fields|
          class << item_fields
            include BuilderMethods
          end
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
        # HTML needs to be esacped by content_tag helper, but
        # does not happen if value is html_safe.  String.new
        # converts back to a regular string value.
        @content = @view_context.content_tag(
          :div, '',
          :class                     => 'nested_item_template',
          :style                     => 'display:none;',
          'data-nested-collection'   => @collection_name,
          'data-next-nested-item'    => @item_name,
          'data-nested-item-content' => String.new(@content)
        )
      end

      module BuilderMethods
        def link_to_delete_item(html_options={}, &b)
          view_context = eval('self', b.binding)
          collection_name = object_name.sub(/\[\d*\]$/, '')
          html_options = HashWithIndifferentAccess.new(html_options)
          html_options[:class] = 'delete_nested_item_link'
          html_options['data-nested-collection'] = collection_name
          html_options['data-nested-item'] = object_name
          view_context.link_to('JavaScript:void(0);', html_options, &b)
        end
      end

    end

  end
end
