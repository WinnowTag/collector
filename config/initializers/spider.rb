Spider.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'spider.log'), 'weekly')
Spider.load_scrapers(File.join(RAILS_ROOT, 'lib', 'scrapers'))