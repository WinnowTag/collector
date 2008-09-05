# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080905014547) do

  create_table "collection_errors", :force => true do |t|
    t.string   "error_type"
    t.text     "error_message"
    t.integer  "feed_id",               :limit => 11
    t.datetime "created_on"
    t.integer  "collection_summary_id", :limit => 11
  end

  create_table "collection_jobs", :force => true do |t|
    t.integer  "feed_id",       :limit => 11
    t.string   "callback_url"
    t.string   "created_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.boolean  "user_notified",               :default => false
    t.integer  "item_count",    :limit => 11
    t.integer  "lock_version",  :limit => 11
    t.text     "message"
    t.boolean  "failed",                      :default => false
  end

  create_table "collection_summaries", :force => true do |t|
    t.string   "fatal_error_type"
    t.text     "fatal_error_message"
    t.integer  "item_count",          :limit => 11, :default => 0
    t.datetime "created_on"
    t.datetime "updated_on"
    t.datetime "completed_on"
  end

  create_table "failed_operations", :force => true do |t|
    t.integer  "item_cache_id",           :limit => 11
    t.integer  "item_cache_operation_id", :limit => 11
    t.integer  "code",                    :limit => 11
    t.string   "message"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "failed_operations", ["item_cache_id", "item_cache_operation_id"], :name => "failed_operations_index", :unique => true

  create_table "feed_item_atom_documents", :force => true do |t|
    t.integer  "feed_item_id",  :limit => 11
    t.binary   "atom_document", :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feed_item_atom_documents", ["feed_item_id"], :name => "index_feed_item_atom_documents_on_feed_item_id", :unique => true

  create_table "feed_item_contents", :force => true do |t|
    t.integer  "feed_item_id",    :limit => 11
    t.text     "title"
    t.string   "link"
    t.string   "author"
    t.text     "description",     :limit => 2147483647
    t.datetime "created_on"
    t.text     "encoded_content"
  end

  add_index "feed_item_contents", ["feed_item_id"], :name => "index_feed_item_contents_on_feed_item_id"

  create_table "feed_items", :force => true do |t|
    t.integer  "feed_id",              :limit => 11
    t.string   "sort_title"
    t.datetime "time"
    t.datetime "created_on"
    t.string   "unique_id",                          :default => ""
    t.string   "time_source",                        :default => "unknown"
    t.integer  "xml_data_size",        :limit => 11
    t.string   "link"
    t.integer  "content_length",       :limit => 11
    t.string   "title"
    t.boolean  "tokens_were_spidered"
  end

  add_index "feed_items", ["link"], :name => "index_feed_items_on_link", :unique => true
  add_index "feed_items", ["time"], :name => "index_feed_items_on_time"
  add_index "feed_items", ["feed_id"], :name => "index_feed_items_on_feed_id"
  add_index "feed_items", ["sort_title"], :name => "index_feed_items_on_title"
  add_index "feed_items", ["unique_id"], :name => "index_feed_items_on_unique_id"
  add_index "feed_items", ["content_length"], :name => "index_feed_items_on_content_length"

  create_table "feed_xml_datas", :force => true do |t|
    t.text     "xml_data",   :limit => 2147483647
    t.datetime "created_on"
    t.datetime "updated_on"
  end

  create_table "feeds", :force => true do |t|
    t.string   "url"
    t.string   "title"
    t.string   "sort_title"
    t.string   "link"
    t.boolean  "active",                                :default => true
    t.integer  "duplicate_id",            :limit => 11
    t.integer  "feed_items_count",        :limit => 11, :default => 0
    t.integer  "collection_errors_count", :limit => 11, :default => 0
    t.integer  "collections_count",       :limit => 11, :default => 0
    t.datetime "updated_on"
    t.datetime "created_on"
    t.string   "created_by"
  end

  add_index "feeds", ["sort_title"], :name => "index_feeds_on_sort_title"
  add_index "feeds", ["title"], :name => "index_feeds_on_title"
  add_index "feeds", ["link"], :name => "index_feeds_on_link"

  create_table "item_cache_operations", :force => true do |t|
    t.string   "action",                                           :null => false
    t.string   "actionable_type",                                  :null => false
    t.integer  "actionable_id",   :limit => 11,                    :null => false
    t.boolean  "done",                          :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_cache_operations", ["created_at"], :name => "index_item_cache_operations_on_created_at"

  create_table "item_caches", :force => true do |t|
    t.string   "base_uri"
    t.boolean  "last_message_failed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version", :limit => 11
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "session_id_idx"

  create_table "spider_results", :force => true do |t|
    t.integer  "feed_item_id",           :limit => 11
    t.integer  "feed_id",                :limit => 11,                    :null => false
    t.boolean  "failed",                               :default => false
    t.text     "failure_message"
    t.text     "content"
    t.text     "scraped_content"
    t.string   "url"
    t.string   "scraper"
    t.integer  "content_length",         :limit => 11
    t.integer  "scraped_content_length", :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "spider_results", ["feed_item_id"], :name => "index_spider_results_on_feed_item_id", :unique => true
  add_index "spider_results", ["feed_id"], :name => "index_spider_results_on_feed_id"
  add_index "spider_results", ["created_at"], :name => "index_spider_results_on_created_at"

  create_table "users", :force => true do |t|
    t.string   "login",                                                      :null => false
    t.string   "firstname"
    t.string   "lastname"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.datetime "last_accessed_at"
    t.string   "time_zone",                               :default => "UTC"
  end

  add_foreign_key "feed_item_contents", ["feed_item_id"], "feed_items", ["id"], :on_delete => :cascade, :name => "feed_item_contents_ibfk_1"

end
