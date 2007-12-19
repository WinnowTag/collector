# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class Spider
  @@default_scraper = BaseScraper.new
  cattr_accessor :default_scraper
  @@scrapers = []
  cattr_reader :scrapers
  
  class << self
    # Loads all the scrapers in a given directory.
    #
    def load_scrapers(directory)
      Dir.glob(File.join(directory, '*.rb')) do |file|
        begin
          require(file).each do |klass|
            scrapers.push(klass.constantize.new)
          end
        rescue Exception => detail
          ActiveRecord::Base.logger.warn("Could not load scraper from #{file}: #{detail}")
        end
      end
    end
    
    # Spiders the content from the given url
    def spider(url)
      spidered_content = nil
      response = Net::HTTP.get_response(URI.parse(url))
      
      case response
      when Net::HTTPResponse
        (scrapers.detect {|s| s.scrapes?(url, response) } or default_scraper).scrape(url, response)        
      end
    end
  end
end