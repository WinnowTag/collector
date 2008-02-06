# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require "bayes/file_token_store"
require "bayes/html_tokenizer"

# Provides a persistant caching tokenizer for Taggables
#
class TaggableTokenizer
  attr_reader :tokenizer, :store, :cache
  def initialize(token_directory = "tokens")
    @cache = {}
    @tokenizer = Bayes::HtmlTokenizer.new(true)
    @store = Bayes::FileTokenStore.new do |store|
      store.token_directory = token_directory
    end
  end
  
  def tokens(taggable)
    tokens_with_counts(taggable).keys
  end
  
  def tokens_with_counts(taggable)
    unless tokens = cache[taggable.taggable_id]
      unless tokens = store.read(taggable.taggable_id)
        tokens = tokenizer.tokens_with_counts(taggable.content)
        store.store(taggable.taggable_id, tokens, :atomized => true)
      end
      cache[taggable.taggable_id] = tokens
    end
    
    tokens
  end
end