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

ActiveRecord::Schema.define(:version => 20081009001913) do

  create_table "collection_errors", :force => true do |t|
    t.integer  "collection_job_id"
    t.integer  "collection_summary_id"
    t.string   "error_type",            :null => false
    t.text     "error_message"
    t.datetime "created_on"
  end

  add_index "collection_errors", ["collection_job_id"], :name => "index_collection_errors_on_collection_job_id", :unique => true

  create_table "collection_jobs", :force => true do |t|
    t.integer  "feed_id"
    t.integer  "collection_summary_id"
    t.string   "http_response_code"
    t.string   "http_last_modified"
    t.string   "http_etag"
    t.integer  "lock_version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "creator_notified_at"
    t.string   "created_by"
    t.string   "callback_url"
    t.string   "state"
    t.integer  "item_count",            :default => 0
    t.float    "utime"
    t.float    "stime"
    t.float    "rtime"
    t.float    "ttime"
  end

  create_table "collection_summaries", :force => true do |t|
    t.string   "fatal_error_type"
    t.text     "fatal_error_message"
    t.integer  "item_count",          :default => 0
    t.datetime "created_on"
    t.datetime "updated_on"
    t.datetime "completed_on"
  end

  create_table "failed_operations", :force => true do |t|
    t.integer  "item_cache_id"
    t.integer  "item_cache_operation_id"
    t.integer  "code"
    t.string   "message"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "failed_operations", ["item_cache_id", "item_cache_operation_id"], :name => "failed_operations_index", :unique => true

  create_table "feed_item_atom_documents", :force => true do |t|
    t.integer  "feed_item_id"
    t.binary   "atom_document", :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feed_item_atom_documents", ["feed_item_id"], :name => "index_feed_item_atom_documents_on_feed_item_id", :unique => true

  create_table "feed_items", :force => true do |t|
    t.integer  "feed_id",           :default => 0
    t.integer  "collection_job_id"
    t.string   "title"
    t.string   "link"
    t.datetime "item_updated"
    t.string   "unique_id"
    t.string   "atom_md5"
    t.integer  "content_length",    :default => 0
    t.datetime "created_on"
    t.string   "sort_title"
  end

  add_index "feed_items", ["link"], :name => "index_feed_items_on_link", :unique => true
  add_index "feed_items", ["item_updated"], :name => "index_feed_items_on_time"
  add_index "feed_items", ["feed_id"], :name => "index_feed_items_on_feed_id"
  add_index "feed_items", ["sort_title"], :name => "index_feed_items_on_title"
  add_index "feed_items", ["unique_id"], :name => "index_feed_items_on_unique_id"
  add_index "feed_items", ["content_length"], :name => "index_feed_items_on_content_length"
  add_index "feed_items", ["collection_job_id"], :name => "index_feed_items_on_collection_job_id"

  create_table "feeds", :force => true do |t|
    t.string   "url"
    t.string   "title"
    t.string   "sort_title"
    t.string   "link"
    t.boolean  "active",                  :default => true
    t.integer  "duplicate_id"
    t.integer  "feed_items_count",        :default => 0
    t.integer  "collection_errors_count", :default => 0
    t.integer  "collections_count",       :default => 0
    t.datetime "updated_on"
    t.datetime "created_on"
    t.string   "created_by"
    t.integer  "lock_version",            :default => 0
  end

  add_index "feeds", ["sort_title"], :name => "index_feeds_on_sort_title"
  add_index "feeds", ["title"], :name => "index_feeds_on_title"
  add_index "feeds", ["link"], :name => "index_feeds_on_link"

  create_table "item_cache_operations", :force => true do |t|
    t.string   "action",                             :null => false
    t.string   "actionable_type",                    :null => false
    t.integer  "actionable_id",                      :null => false
    t.boolean  "done",            :default => false, :null => false
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
    t.integer "version"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "session_id_idx"

  create_table "spider_results", :force => true do |t|
    t.integer  "feed_item_id"
    t.integer  "feed_id",                                   :null => false
    t.boolean  "failed",                 :default => false
    t.text     "failure_message"
    t.text     "content"
    t.text     "scraped_content"
    t.string   "url"
    t.string   "scraper"
    t.integer  "content_length"
    t.integer  "scraped_content_length"
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

end
