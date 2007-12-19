# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'hpricot'

# = Feed Item Tokenizer
#
# The FeedItemTokenizer extends Bayes::HtmlTokenizer to add some feed item
# specific tokens, integrate it with the token storage and a caching capability.
#
class FeedItemTokenizer < Bayes::HtmlTokenizer
  @@minimum_tokens = 60
  cattr_accessor :minimum_tokens
  
  def initialize
    super(false)
  end
    
  # Gets the tokens for a FeedItem.
  #
  # If the tokens don't exist already they are created.
  #
  def tokens(feed_item)
    (feed_item.tokens or tokens_with_counts(feed_item).keys)
  end
  
  # Gets the tokens and token counts for a feed item.
  #
  # If the tokens don't exist they are created.
  #
  def tokens_with_counts(feed_item)
    tokenize(feed_item)
  end
  
  private
  # Performs the actual tokenization of a feed item
  #
  def tokenize(feed_item)
    feed_item.tokens_with_counts = if feed_item.content.encoded_content
      tokens = super(feed_item.content.encoded_content)
    
      if tokens.size < FeedItemTokenizer.minimum_tokens && feed_item.link
        ActiveRecord::Base.logger.info "Only got #{tokens.size} tokens for content of #{feed_item.link}"
        if spidered_content = Spider.spider(feed_item.link)
          tokens = super(spidered_content)
          feed_item.tokens_were_spidered = true
        end
      end
      
      if feed_item.content.title         
        feed_item.content.title.downcase.gsub(/[^a-z0-9]/, ' ').split.each do |title_token|
          tokens[title_token] += 1
        end
      end
    
      # Author gets added without splitting or case folding
      tokens[feed_item.content.author] += 1 if feed_item.content.author
      tokenize_uri(feed_item.attributes['link']).each do |link_token|
        tokens[link_token] += 1
      end
            
      # localize the tokens
      Bayes::TokenAtomizer.get_atomizer.localize(tokens)
    else
      {}
    end
  end
end
