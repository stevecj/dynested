function Dynested() {
}

(function () {
  function fieldNameToId(fieldName) {
    return fieldName.replace(/\[/g, '_').replace(/\]/g, '');
  }
  Dynested.fieldNameToId = fieldNameToId;

  function Collection(name) {
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

    function addNewItem() {
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
    }
    this.addNewItem = addNewItem;
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
    function remove() {
      var itemElement = $('.nested_item[data-nested-item="' + name + '"]');
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

  $(document).ready( function () {
    $('.new_nested_item_link').live('click', function() {
      Dynested.addItemFor(this);
    });
  });
})();
