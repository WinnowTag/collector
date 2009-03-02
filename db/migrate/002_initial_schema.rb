# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class InitialSchema < ActiveRecord::Migration
  def self.up   
    create_table :users do |t|
      t.column :login, :string, :null => false
      t.column :firstname, :string
      t.column :lastname, :string
      t.column :email, :string
      t.column :crypted_password, :string, :limit => 40
      t.column :salt, :string
      t.column :remember_token, :string
      t.column :remember_token_expires_at, :datetime
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :logged_in_at, :datetime
      t.column :last_accessed_at, :datetime
    end

    # Creating these tables so migration run from start to finish.
    create_table :feed_items do |t|
      t.integer :feed_id, :default => 0
      t.integer :collection_job_id
      t.string :title
      t.string :link
      t.datetime :time
      t.string :unique_id
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
      t.datetime :updated_on
      t.datetime :created_on
      t.integer :lock_version, :default => 0
      t.string :uri
      t.text :last_http_headers
      t.boolean :is_duplicate
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
    
    create_table "schema_info", :id => false do |t|
      t.integer "version"
    end
    execute "alter table schema_info ENGINE=MYISAM;"
    
    create_table "feed_xml_datas" do |t|
      t.text     "xml_data",   :limit => 2147483647
      t.datetime "created_on"
      t.datetime "updated_on"
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
