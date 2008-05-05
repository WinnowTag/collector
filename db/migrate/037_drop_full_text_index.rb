class DropFullTextIndex < ActiveRecord::Migration
  def self.up
    drop_table(:feed_item_contents_full_text)
  end

  def self.down
  end
end
