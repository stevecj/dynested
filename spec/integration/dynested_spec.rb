require 'spec_helper'

describe "Dynested" do
  include Capybara::DSL
  
  context "editing an album with 2 tracks, and 1 review, sorted by name" do
    before(:each) do
      @album = Album.create(
        :title => "Bits n' Bytes",
        :tracks_attributes => [
          { :title => "Byte Me",       :duration_seconds => 255 },
          { :title => "Streamin Down", :duration_seconds => 384 }
        ],
        :reviews_attributes => [
          { :review => "Music to code by!" }
        ]
      )
      visit edit_album_path(@album)
    end

    # TODO: Many of the tests in here are not really integration tests,
    # but don't really know how to test them in isolation yet.  Should
    # fix that sooner or later.

    it "should generate the elements that fields_for would" do
      page.should have_selector('input#album_tracks_attributes_0_title[value="Byte Me"]')
      page.should have_selector('input#album_tracks_attributes_0_duration_seconds[value="255"]')
      page.should have_selector('input#album_tracks_attributes_0_id[value="%d"]' % @album.tracks[0].id)

      page.should have_selector('input#album_tracks_attributes_1_id[value="%d"]' % @album.tracks[1].id)
    end
    
    it "should wrap each item in an appropriately constructed div" do
      wrapper_selector_common =
        'div' +
        '.nested_item' +
        '[data-nested-collection="album[tracks_attributes]"]'

      within(
        wrapper_selector_common + '#album_tracks_attributes_0[data-nested-item="album[tracks_attributes][0]"]'
      ) do
        page.should have_selector('input#album_tracks_attributes_0_title[value="Byte Me"]')
        page.should have_selector('input#album_tracks_attributes_0_id[value="%d"]' % @album.tracks[0].id)
      end

      within(
        wrapper_selector_common + '#album_tracks_attributes_1[data-nested-item="album[tracks_attributes][1]"]'
      ) do
        page.should have_selector('input#album_tracks_attributes_1_title[value="Streamin Down"]')
        page.should have_selector('input#album_tracks_attributes_1_id[value="%d"]' % @album.tracks[1].id)
      end

      page.should have_no_selector('#album_tracks_attributes_2')
    end

    it "should render with an empty new item if desired" do
      # Sanity check.
      page.should have_selector('input#album_reviews_attributes_0_id')

      page.should have_selector('.nested_item#album_reviews_attributes_1')
      # New items do not have id attributes.
      page.should have_no_selector('input#album_reviews_attributes_1_id')
    end

    it "should generate a template for a next new item" do
      template_selector = \
        '.nested_item_template' +
        '[data-nested-collection="album[tracks_attributes]"]'

      page.should have_selector(template_selector)
      template = page.find(template_selector)
      template['data-next-nested-item'].should == 'album[tracks_attributes][2]'
      template['data-nested-item-content'].should =~
        /^\s*<div\s.*\sdata-nested-item\s*="album\[tracks_attributes\]\[2\]".*<\/div>\s*$/m
    end

    it "should generate an add-item link" do
      within(
        'a.new_nested_item_link[data-nested-collection="album[tracks_attributes]"]'
      ) do
        page.should have_content 'Add new track'
      end
    end

    it "should generate delete-item links" do
      selectors = (0..1).map do |n|
        ( '#album_tracks_attributes_%d ' +
            'a' +
            '.delete_nested_item_link' +
            '[data-nested-collection="album[tracks_attributes]"]' +
            '[data-nested-item="album[tracks_attributes][%d]"]'
        ) % [n, n]
      end
      selectors.each do |selector|
        within selector do
          page.should have_content 'Delete track'
        end
      end
    end

  end

  context "with javascript" do
    before(:each) do
      Capybara.current_driver = :selenium
    end

    context "editing an album with 2 existing tracks, sorted by name" do
      before(:each) do
        @album = Album.create(
          :title => "Bits n' Bytes",
          :tracks_attributes => [
            { :title => "Byte Me",       :duration_seconds => 255 },
            { :title => "Streamin Down", :duration_seconds => 384 }
          ],
          :reviews_attributes => [
            { :review => "Music to code by!" }
          ]
        )
        visit edit_album_path(@album)
      end

      it "should supply a memoized collection object for a collection name" do
        page.execute_script('Dynested.collection("foo").thisIsMe = "yes";')
        nameValue = page.evaluate_script('Dynested.collection("foo").name')
        thisIsMeValue = page.evaluate_script('Dynested.collection("foo").thisIsMe')

        nameValue.should == 'foo'
        thisIsMeValue.should == 'yes'
      end

      it "should supply a memoized item object for an item name" do
        page.execute_script('Dynested.item("foo[5]").thisIsMe = "yes";')
        nameValue = page.evaluate_script('Dynested.item("foo[5]").name')
        thisIsMeValue = page.evaluate_script('Dynested.item("foo[5]").thisIsMe')

        nameValue.should == 'foo[5]'
        thisIsMeValue.should == 'yes'
      end

      it "should provide access to an item's collection object" do
        collectionName = page.evaluate_script('Dynested.item("foo[bars_attributes][5]").collection.name')
        collectionName.should == 'foo[bars_attributes]'
      end

      it "should expose a collection's template element" do
        next_nested_item_name = page.evaluate_script(
          "Dynested.collection('album[tracks_attributes]').template().attr('data-next-nested-item');"
        )
        next_nested_item_name.should == 'album[tracks_attributes][2]';
      end

      it "should add a new collection item element as a sibling of the template element" do
        page.execute_script "Dynested.collection('album[tracks_attributes]').addNewItem();"
        page.should have_selector(
          '.nested_item[data-nested-item="album[tracks_attributes][2]"]~' +
          '.nested_item_template[data-nested-collection="album[tracks_attributes]"]'
        )
      end

      it "should update the template when a new collection item is added" do
        page.execute_script "Dynested.collection('album[tracks_attributes]').addNewItem();"
        template_selector = \
          '.nested_item_template' +
          '[data-nested-collection="album[tracks_attributes]"]'

        page.should have_selector(template_selector)
        template = page.find(template_selector)
        template['data-next-nested-item'].should == 'album[tracks_attributes][3]'
        template['data-nested-item-content'].should =~ /"album\[tracks_attributes\]\[3\]/
        template['data-nested-item-content'].should_not =~ /"album\[tracks_attributes\]\[2\]/
        template['data-nested-item-content'].should =~ /"album_tracks_attributes_3/
        template['data-nested-item-content'].should_not =~ /"album_tracks_attributes_2/
      end

      it "should remove an existing item by flagging and hiding" do
        page.execute_script "Dynested.item('album[tracks_attributes][1]').remove();"
        page.should have_selector('#album_tracks_attributes_1__destroy[value="true"]')
        within '#album_tracks_attributes_1' do
          page.should have_xpath("//*[text()='Title']", :visible => false)
        end
      end

      it "should remove a new item by deleting its content from the page" do
        # Sanity check
        page.should have_selector('[data-nested-item="album[reviews_attributes][1]"]')

        page.execute_script "Dynested.item('album[reviews_attributes][1]').remove();"
        page.should have_no_selector('[data-nested-item="album[reviews_attributes][1]"]')
      end

      it "should make add-new links work" do
        click_link 'Add new track'
        page.should have_selector('.nested_item[data-nested-item="album[tracks_attributes][2]"]')
      end

      it "should make remove links work" do
        within '#album_tracks_attributes_1' do
          click_link 'Delete track'
        end
        within '#album_tracks_attributes_1' do
          page.should have_xpath("//*[text()='Title']", :visible => false)
        end
      end

      it "should allow for cancelable before-add handlers" do
        # Sanity check.
        page.should have_no_selector('.nested_item[data-nested-item="album[tracks_attributes][2]"]')

        page.execute_script <<-HERE
document.beforeAddTestNum = 0;
document.testCollection = Dynested.collection("album[tracks_attributes]");
document.testCollection.beforeAddItem(function () {
  document.beforeAddTestNum += 1;
  if( document.beforeAddTestNum == 1 ) { 
    return true;  // Proceed on first invocation.
  } else {
    return false;  // Cancel on subsequent invocations.
  }
});
document.testCollection.addNewItem();
HERE
        timesInvoked = page.evaluate_script('document.beforeAddTestNum')
        timesInvoked.should == 1
        page.should have_selector('.nested_item[data-nested-item="album[tracks_attributes][2]"]')

        page.execute_script 'document.testCollection.addNewItem();'
        timesInvoked = page.evaluate_script('document.beforeAddTestNum')
        timesInvoked.should == 2
        page.should have_no_selector('.nested_item[data-nested-item="album[tracks_attributes][3]"]')
      end

      it "should execute a before-add handler in the context of its collection" do
        page.execute_script <<-HERE
document.testCollection = Dynested.collection("album[tracks_attributes]");
document.testCollection.beforeAddItem(function () {
  document.testCollectionName = this.name;
});
document.testCollection.addNewItem();
HERE
        contextName = page.evaluate_script('document.testCollectionName')
        contextName.should == 'album[tracks_attributes]'
      end

      it "should allow for cancelable before-remove handlers" do
        # Sanity check.
        page.should have_css('#album_tracks_attributes_0', :visible => true)
        page.should have_css('#album_tracks_attributes_1', :visible => true)

        page.execute_script <<-HERE
document.beforeRemoveTestNum = 0;
Dynested.collection('album[tracks_attributes]').beforeRemoveItem(function () {
  document.beforeRemoveTestNum += 1;
  if( this.name == 'album[tracks_attributes][0]' ) {
    return true; // Proceed to delete item 0.
  } else {
    return false; // Cancel deleting any other item.
  }
});
Dynested.item("album[tracks_attributes][0]").remove();
HERE
        timesInvoked = page.evaluate_script('document.beforeRemoveTestNum')
        timesInvoked.should == 1
        page.should have_no_css('#album_tracks_attributes_0', :visible => true)

        page.execute_script 'Dynested.item("album[tracks_attributes][1]").remove();'
        timesInvoked = page.evaluate_script('document.beforeRemoveTestNum')
        timesInvoked.should == 2
        # This test passes even when changed to that it should break
        page.should have_css('#album_tracks_attributes_1')
      end

      it "should allow for after-add handlers"

      it "should allow for after-delete handlers"

      it "should allow for after-add-or-delete handlers"

      it "should expose a collection's items list"

      it "should expose a collection's last item"

      it "should expose a collection's exept-last items list"
    end
  end
end
