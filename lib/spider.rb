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
          require(file)
          
          scraper = File.basename(file).sub('.rb', '').camelize.constantize.new
          if scraper.respond_to?(:scrape)
            scrapers.push(scraper)
          else
            ActiveRecord::Base.logger.warn("Got a scraper (#{klass}) that doesn't respond to :scrape")
          end
        rescue Exception => detail
          puts "Could not load scraper from #{file}: #{detail}"
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
        content = nil
        scrapers.each do |s| 
          (content = s.scrape(url, response)) and break
        end 
        
        content or default_scraper.scrape(url, response)        
      end
    end
  end
end