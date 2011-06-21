require 'spec_helper'

describe "Dynested" do
  include Capybara::DSL
  
  context "editing an album with 2 existing tracks, sorted by name" do
    before(:each) do
      @album = Album.create(
        :title => "Bits n' Bytes",
        :tracks_attributes => [
          { :title => "Byte Me",       :duration_seconds => 255 },
          { :title => "Streamin Down", :duration_seconds => 384 }
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
    end

    it "should generate a template for a next new item" do
      page.should have_selector \
        '.nested_item_template' +
        '[data-nested-collection="album[tracks_attributes]"]' +
        '[data-next-nested-item="album[tracks_attributes][2]"]'
      within(
        '.nested_item_template' +
        '[data-nested-collection="album[tracks_attributes]"]'
      ) do
        page.should have_selector \
          'input#album_tracks_attributes_2_title[name="album[tracks_attributes][2][title]"]'
      end
    end
  end
end
