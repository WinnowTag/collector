# Allow a configurable base uri for generate URLs within atom documents

base_uri_file = File.join(RAILS_ROOT, "config", "base_uri.yml")

if File.exists?(base_uri_file)
  Feed.base_uri = FeedItem.base_uri = File.read(base_uri_file)
end
  