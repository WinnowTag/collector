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
  @@logger = ActiveRecord::Base.logger
  cattr_accessor :logger
  
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
      response = fetch(url)
      logger.info "Attempting to spider #{url}: status = #{response.code}, length = #{response.content_length}"
      
      case response
      when Net::HTTPResponse
        content = nil
        scrapers.each do |s| 
          if content = s.scrape(url, response)
            logger.info "Spidered content was scraped by '#{s}', length = #{content.size} "
            break
          end
        end 
        
        content or default_scraper.scrape(url, response)        
      end
    end
    
    private
    def fetch(url, redirection_limit = 5)
      if redirection_limit < 1
        logger.warn "#{url} redirected more than 5 times"
        return nil
      end
      
      response = Net::HTTP.get_response(URI.parse(url))
      
      case response
      when Net::HTTPRedirection then fetch(response['Location'], redirection_limit - 1)
      when Net::HTTPSuccess then response        
      end        
    end
  end
end