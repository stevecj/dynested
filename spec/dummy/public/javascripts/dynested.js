function Dynested() {
}

(function () {
  function fieldNameToId(fieldName) {
    return fieldName.replace(/\[/g, '_').replace(/\]/g, '');
  }
  Dynested.fieldNameToId = fieldNameToId;

  function Collection(name) {
    thisCollection = this;
    this.name = name;

    function template() {
      return $(
        '.nested_item_template[data-nested-collection="' + this.name + '"]'
      );
    }
    this.template = template;

    var items = {};
    function item(itemName) {
      if( items[itemName] ) { return items[itemName]; }
      items[itemName] = new Dynested.Item(this, itemName);
      return items[itemName];
    }
    this.item = item;

    var beforeAddItemHandlers = [];
    function beforeAddItem(fn) {
      beforeAddItemHandlers.push(fn);
    }
    this.beforeAddItem = beforeAddItem;

    var beforeRemoveItemHandlers = [];
    function beforeRemoveItem(fn) {
      beforeRemoveItemHandlers.push(fn);
    }
    this.beforeRemoveItem = beforeRemoveItem;

    var afterAddItemHandlers = [];
    function afterAddItem(fn) {
      afterAddItemHandlers.push(fn);
    }
    this.afterAddItem = afterAddItem;

    var afterRemoveItemHandlers = [];
    function afterRemoveItem(fn) {
      afterRemoveItemHandlers.push(fn);
    }
    this.afterRemoveItem = afterRemoveItem;

    function afterAddOrRemoveItem(fn) {
    }
    this.afterAddOrRemoveItem = afterAddOrRemoveItem;

    function addNewItem() {
      var proceed = true;
      $.each(beforeAddItemHandlers, function (fn) {
        proceed = proceed && this.call(thisCollection);
      });
      if( ! proceed ) { return false; }

      var t = this.template();
      var iName = t.attr('data-next-nested-item');
      var iId = Dynested.fieldNameToId(iName);
      var nMatch = iName.match( /^(.*\[)(\d*)(\]$)/ );
      var iNextName = nMatch[1] + (parseInt(nMatch[2]) + 1) + nMatch[3];
      var iNextId = Dynested.fieldNameToId(iNextName);
      var content = t.attr('data-nested-item-content');
      t.before( content );
      var nextContent = $(document.createElement('div'));
      nextContent.html( content );
      nextContent.find('*').each( function () {
        Collection.updateIdentifier($(this), 'id',   iId,   iNextId);
        Collection.updateIdentifier($(this), 'for',  iId,   iNextId);
        Collection.updateIdentifier($(this), 'name', iName, iNextName);
        Collection.updateIdentifier($(this), 'data-nested-item', iName, iNextName);
      });
      t.attr('data-nested-item-content', nextContent.html());
      t.attr('data-next-nested-item', iNextName);
      var newItem = this.item(iName);

      $.each(afterAddItemHandlers, function() {
        this.call(newItem);
      });
      return true;
    }
    this.addNewItem = addNewItem;

    function handleBeforeRemoveItem(item) {
      var proceed = true;
      $.each(beforeRemoveItemHandlers, function () {
        proceed = proceed && this.call(item);
      });
      return proceed;
    }
    this.handleBeforeRemoveItem = handleBeforeRemoveItem;

    function handleAfterRemoveItem(details) {
      var proceed = true;
      $.each(afterRemoveItemHandlers, function () {
        this.call(thisCollection, details);
      });
      return proceed;
    }
    this.handleAfterRemoveItem = handleAfterRemoveItem;

    function currentItems() {
      itemElements = $('.nested_item[data-nested-collection="' + this.name + '"]');
      result = [];
      var iName;
      $.each(itemElements, function () {
        iName = $(this).attr('data-nested-item');
        // Add to result unless flagged as destroyed.
        if( $(this).find('input[name="' + iName + '[_destroy]"][value="true"]').length == 0 ) {
          result.push( thisCollection.item(iName) );
        }
      });
      return result;
    }
    this.currentItems = currentItems;
  }
  Dynested.Collection = Collection;

  function updateIdentifier(element, attrName, oldPrefix, newPrefix) {
    var attrVal = $(element).attr(attrName);
    if( ! attrVal ) { return; }
    if( attrVal.length < oldPrefix.length ) { return; }
    if( attrVal.substr(0, oldPrefix.length) != oldPrefix ) { return; }
    if( attrVal.length > oldPrefix.length &&
        attrVal.substr(oldPrefix.length, 1).match(/[^_\[]/)
    ) { return; }

    element.attr( attrName, newPrefix + attrVal.substr(oldPrefix.length) );
  }
  Collection.updateIdentifier = updateIdentifier;


  var collections = {};
  function collection(name) {
    if( collections[name] ) { return collections[name]; }
    collections[name] = new Collection(name);
    return collections[name];
  }
  Dynested.collection = collection;

  function Item(collection, name) {
    this.collection = collection;
    this.name = name;

    function elements() {
      return $('.nested_item[data-nested-item="' + this.name + '"]');
    }
    this.elements = elements;

    function remove() {
      if( ! this.collection.handleBeforeRemoveItem(this) ) { return false; }
      var itemElement = this.elements();
      var idFieldName = this.name + '[id]';
      if( $('input[name="' + idFieldName + '"]').length > 0 ) {
        // Existing saved item (has id field), so flag for destruction, and hide.
        var destroyFieldName = this.name + '[_destroy]';
        $('input[name="' + destroyFieldName + '"]').val('true');
        itemElement.hide();
      } else {
        // Unsaved item, so simply remove from page.
        itemElement.remove();
      }
      this.collection.handleAfterRemoveItem({
        itemName: this.name,
        removedElements: itemElement
      });
      return true;
    }
    this.remove = remove;
  }
  Dynested.Item = Item;

  function collectionNameFromItemName(itemName) {
    return itemName.replace(/\[\d+\]$/, '');
  }
  Item.collectionNameFromItemName = collectionNameFromItemName;

  function item(name) {
    var collectionName = Dynested.Item.collectionNameFromItemName(name);
    var collection = Dynested.collection(collectionName);
    return collection.item(name)
  }
  Dynested.item = item;

  function addItemFor(element) {
    var collectionName = $(element).attr('data-nested-collection');
    var collection = Dynested.collection(collectionName);
    collection.addNewItem();
  }
  Dynested.addItemFor = addItemFor;

  function removeItemFor(element) {
    var itemName = $(element).attr('data-nested-item');
    var item = Dynested.item(itemName);
    item.remove();
  }
  Dynested.removeItemFor = removeItemFor;

  $(document).ready( function () {
    $('.new_nested_item_link').live('click', function() {
      Dynested.addItemFor(this);
    });
    $('.delete_nested_item_link').live('click', function() {
      Dynested.removeItemFor(this);
    });
  });
})();
