class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.integer :album_id
      t.string :note

      t.timestamps
    end
  end

  def self.down
    drop_table :notes
  end
end
