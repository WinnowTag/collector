# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class Spider
  class Result
    attr_accessor :content, :scraper_name
    def initialize(content, scraper_name)
      @content, @scraper_name = content, scraper_name
    end
  end
  
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
      logger.info "Attempting to spider #{url}..."
      response = fetch(url)
      
      case response
      when Net::HTTPResponse
        logger.info "  => got 200, content_length = #{response.content_length} ..."
        
        scraper = nil
        content = nil
        scrapers.each do |scraper| 
          if content = scraper.scrape(url, response)
            logger.info "  => spidered content was scraped by '#{scraper}', length = #{content.size}."
            break
          end
        end 
        
        if content.nil?
          logger.info "  => no scraper for #{url}."
          content = default_scraper.scrape(url, response)
          scraper = default_scraper
        end
        
        Result.new(content, scraper.name)
      else
        logger.info "  => could not get #{url}. (#{response.code}) #{response.message}"
      end
    end
    
    private
    def fetch(url, redirection_limit = 5)      
      case response = Net::HTTP.get_response(URI.parse(url))
      when Net::HTTPRedirection 
        if redirection_limit < 1
          logger.warn "  => #{url} redirected more than 5 times"
          response
        else
          fetch(response['Location'], redirection_limit - 1)
        end
      when Net::HTTPSuccess then response        
      end        
    end
  end
end