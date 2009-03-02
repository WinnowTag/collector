# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ArchiveTables < ActiveRecord::Migration
  def self.up
    # Creating these tables so migration run from start to finish.
    create_table :feed_items do |t|
      t.integer :feed_id, :default => 0
      t.integer :collection_job_id
      t.string :title
      t.string :link
      t.datetime :time
      t.string :unique_id
      t.string :atom_md5
      t.integer :content_length, :default => 0
      t.datetime :created_on
      t.string :sort_title
    end
    add_index :feed_items, :feed_id
    add_index :feed_items, :collection_job_id
    add_index :feed_items, :time
    add_index :feed_items, :unique_id
    add_index :feed_items, :content_length
    add_index :feed_items, :sort_title

    create_table :feeds do |t|
      t.string :url
      t.string :title
      t.string :sort_title
      t.string :link
      t.boolean :active, :default => true
      t.integer :duplicate_id
      t.integer :feed_items_count, :default => 0
      t.integer :collection_errors_count, :default => 0
      t.integer :collections_count, :default => 0
      t.datetime :updated_on
      t.datetime :created_on
      t.string :created_by
      t.integer :lock_version, :default => 0
      t.string :uri
    end
    add_index :feeds, :uri, :unqiue => true
    add_index :feeds, :sort_title

    create_table "feed_item_xml_data" do |t|
      t.text     "xml_data",   :limit => 2147483647
      t.datetime "created_on"
    end

    create_table "feed_item_contents" do |t|
      t.integer  "feed_item_id",    :limit => 11
      t.text     "title"
      t.string   "link"
      t.string   "author"
      t.text     "description",     :limit => 2147483647
      t.datetime "created_on"
      t.text     "encoded_content"
    end
    execute "ALTER TABLE feed_item_contents ENGINE=MYISAM;"
    add_index :feed_item_contents, :feed_item_id, :name => "feed_item_contents_feed_item_id_index"
    execute "ALTER TABLE feed_item_contents ADD FULLTEXT fti_feed_item_contents(title, author, description);"
    
    execute "create table feed_items_archives like feed_items;"
    add_column :feed_items_archives, :position, :integer
    execute "create table feed_item_xml_data_archives like feed_item_xml_data;"
    # execute "create table feed_item_tokens_containers_archives like feed_item_tokens_containers;"
    execute "create table feed_item_contents_archives like feed_item_contents;"
    
    # remove full text index index from archived content
    execute "drop index fti_feed_item_contents on feed_item_contents_archives;"
    
    say "About to remove any orphaned xml or token rows... this could take a while."
    execute "delete from feed_item_xml_data where id not in (select id from feed_items);"
    # execute "delete from feed_item_tokens_containers where feed_item_id not in (select id from feed_items);"
    
    say "Creating foreign keys for feed item tables"
    # Create some foreign keys to make deletion of archived items easier
    execute "alter table feed_item_xml_data add " +
            " foreign key FI_XML_DATA (id) references feed_items(id) on delete cascade;"
    # execute "alter table feed_item_tokens_containers add " +
    #         " foreign key FI_TOKENS (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
    raise IrreversibleMigration
  end
end
