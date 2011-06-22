function Dynested() {
}

(function () {
  function fieldNameToId(fieldName) {
    return fieldName.replace(/\[/g, '_').replace(/\]/g, '');
  }

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

  function Collection(name) {
    this.name = name;
    this.template = function() {
      return $(
        '.nested_item_template[data-nested-collection="' + this.name + '"]'
      );
    };
    this.addNewItem = function () {
      var t = this.template();
      var iName = t.attr('data-next-nested-item');
      var iId = fieldNameToId(iName);
      var nMatch = iName.match( /^(.*\[)(\d*)(\]$)/ );
      var iNextName = nMatch[1] + (parseInt(nMatch[2]) + 1) + nMatch[3];
      var iNextId = fieldNameToId(iNextName);
      var tClone = t.clone();
      tClone.find('*').each( function () {
        updateIdentifier($(this), 'id',   iId,   iNextId);
        updateIdentifier($(this), 'for',  iId,   iNextId);
        updateIdentifier($(this), 'name', iName, iNextName);
        updateIdentifier($(this), 'data-nested-item', iName, iNextName);
      });
      t.attr('data-next-nested-item', iNextName);
      var oldTemplateHtml = t.html();
      t.html( tClone.html() );
      t.before( oldTemplateHtml );
    };
  }

  var collections = {};
  function collection(name) {
    if( collections[name] ) { return collections[name]; }
    collections[name] = new Collection(name);
    return collections[name];
  }

  function Item(name) {
    this.name = name;
    this.deleteIt = function () {
      var destroyFieldName = this.name + '[_destroy]';
      $('input[name="' + destroyFieldName + '"]').val('true');
      $('.nested_item[data-nested-item="' + name + '"]').hide();
    };
  }

  var items = {};
  function item(name) {
    if( items[name] ) { return items[name]; }
    items[name] = new Item(name);
    return items[name];
  }

  Dynested.Collection = Collection;
  Dynested.collection = collection;
  Dynested.Item = Item;
  Dynested.item = item;
})();
