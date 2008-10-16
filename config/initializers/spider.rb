ActiveSupport::Dependencies.load_once_paths << File.join(RAILS_ROOT, 'lib', 'spider.rb')
ActiveSupport::Dependencies.load_once_paths << File.join(RAILS_ROOT, 'lib', 'scrapers')
Spider.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'spider.log'))
Spider.load_scrapers(File.join(RAILS_ROOT, 'lib', 'scrapers'))
