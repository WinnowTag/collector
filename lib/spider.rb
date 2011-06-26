# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

class Spider  
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

      begin
        case response = fetch(url)
        when Net::HTTPSuccess
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
            SpiderResult.new(
                :url => url,
                :content => response.body,
                :failed => true,
                :failure_message => 'No scraper for content'
              )
          else
            SpiderResult.new(
                :url => url,
                :content => response.body,
                :scraped_content => content, 
                :scraper => scraper.name
              )
          end
        when Net::HTTPResponse
          logger.info "  => could not get #{url}. (#{response.code}) #{response.message}"
          SpiderResult.new(
              :url => url,
              :failed => true,
              :failure_message => "Retrieval Failure: (#{response.code}) #{response.message}"
            )        
        end
      rescue Exception => e
        logger.info("  => exception fetching #{url}: #{e.message}")
        SpiderResult.new(
            :url => url,
            :failed => true,
            :failure_message => "Spider Error: #{e.message}"
          )
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
      else
        response        
      end
    end
  end
end