# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
#
# Created by Sean Geoghegan (28 December 2006).
#
require 'rubygems'
gem 'RubyInline'
require 'inline'

module Bayes # :nodoc:
  # The Peerworks implementation of Bayesian Classifier.
  #
  # This is inspired by SpamBayes but modified to support
  # multiple classification pools instead of the SpamBayes
  # Ham and Spam pools.
  #
  # == Handling Backgrounds ==
  #
  # Initially the background was the combination of all other tags however,
  # when including tokens that are only in the background when computing
  # probabilities this produced a huge bias in favour of negatives, so for
  # a while we were ignoring tokens that only existed in the background.
  # This of course had the side effect of favouring positives but not as
  # dramatically as including them would favour negatives.
  #
  # I (Sean) had a theory that the reason that the bias would be so strongly
  # biased to negatives was because the variety of tokens in the background
  # is so huge, the chance of a token occuring in the background is so much
  # higher than in the foreground. This is directly related to another thing 
  # that was bugging me for a while.  Say you have three tags, 'politics', 
  # 'media' and 'right wing'; three different items are each tagged with one 
  # of those tags and each of these items has the word 'Bush'.  When you then 
  # compute the probability for the token 'Bush' in any of the three tags it 
  # becomes a negative token for any one of the pools because it appears in 
  # the background pool more than in the foreground because the background 
  # pool contains the tokens from other two tags.  Now clearly, Bush could 
  # probably be a strong indicator for any of those pools but by building the 
  # background pool out of all the other pools it becomes a negative token.
  #
  # So to counter this I did some experiments using just the unwanted tag as the
  # background.  This yielded pretty good results, with 57% true positives and
  # 99% true negatives for normal tags.
  #
  # To support this I have added a parameters to the initialize method:
  #
  #   :background_pool_name - The names of pools to use as the background.
  #
  # Currently only one pool name is supported.  This pool will be used as the
  # background for all other pools and the union of all other pools will be used
  # as the background for that pool.
  #
  # If no background pool is specified, the original behaviour of the union of all
  # other tags will be used.
  #
  ## === Further work on backgrounds ===
  #
  # We then thought it would be interesting to try other backgrounds, such as 'seen'.
  # Initial testing using 'seen' as the background gave about a 20% increase in true positives
  # and only a 6% drop in true negatives.  
  #
  # 'unwanteds' suffered badly in this scheme though, so we required the addition of
  # another configuration parameter to define a list of pools that would use the entire
  # foreground union as their background instead of the background specified by
  # :background_pool_name.  This provided excellent performance for both normal and unwanted
  # tags.
  #
  # There was one more variation to try though. Using everything except 'seen' and 'unwanted'
  # as the background for normal tags.  I tried this it gave the worst results in terms of
  # true positives (around 30%).
  #
  # So the best solution seems to be using 'seen' as the background for normal tags and the
  # union of all normal tags as the background for 'unwanted' tags.
  #
  # === Update to background handling ==
  #
  # After making the changes to the Bayesian adjustment that better account for imbalances between
  # the foreground and background, the tests for different backgrounds were run again.  In this
  # case, the 'seen' as background solution gave the worst results and unwanted as background
  # and 'not tag' as background both gave fairly good results with unwanted slightly higher.  
  #
  # The outcome of this was that the special handling of backgrounds was removed and we went back
  # to using 'not tag' as the background.  Even though using 'unwanted' was slightly higher, using
  # 'not tag' is simpler and also less specific to individual tagging habits.
  #
  # I think you can assume that the use of 'seen' as background performed better originally because it
  # was a way of reducing the imbalance between the foreground and background tags. The modified 
  # Bayesian Adjustment clearly does a better job of fixing the imbalance and gives better results without
  # having to specifically handle background selection.
  #
  # == Handling n in the Bayesian Adjustment ==
  #
  # Previously n was just pool.tokens[token] + other_token_count.
  # This has a built in assumption that the foreground and background
  # pools are roughly the same size and a token occuring a few times in
  # the foreground is equal in value to a token occuring a few times in 
  # the background.  This assumption doesn't hold for our purposes, 
  # or perhaps for multi-label classifiers in general.
  #
  # In our case the foreground pool is likely to be much smaller than
  # the background pool, just because people will tag less items than
  # they don't or if we are using pools built using a tag and not tag
  # method then background will consist of all the items tagged with 
  # other tags by the user.
  #
  # I did find a method for scaling n referenced in this article at
  # http://www.bgl.nu/bogofilter/param.html. It would scale n by the
  # ratio of the sizes between the foreground and background. However
  # it would scale the foreground token count by the same factor that
  # it will scale the background token count.  So it does still assume
  # some symmetricality, or at least that you want to treat rare tokens
  # in a large the same way as rare tokens in a smaller pool.
  #
  # We would like to be able to treat rare tokens in smaller pools as being
  # higher indicators of the token occuring in that pool that rare tokens
  # within large pools.  This is essentially preserving some of the information
  # in the pool_ratio and other_ratio that gets normalized by the initial
  # calculation of probability.
  #
  # So to achieve this I (Sean) came up with the idea of multiplying the token
  # count in the foreground by the ratio between the background and foreground 
  # and dividing the token count in the background by the same ratio then adding
  # these two figures together to get the value for n. This has the effect that
  # when the foreground and background are largely asymmetric in size a token 
  # appearing only in the smaller pool has a larger weight than a token appearing
  # only in the larger pool.
  #
  # From a results point of view, this pulled alot of the true positives
  # up from 0% in the lower training count bins and had no negative impact
  # on true negatives.
  #
  # == Post processing to enforce exclusivity ==
  #
  # Under #287 we added a post processing section to enforce the exclusivity of
  # unwanted tags. This added the with_raw parameter than when true will return
  # an array with two elements, the first being the post-processed results and
  # the second being the raw results.
  #
  # After some additional improvements and the addition the training count report
  # we discovered that this change actually hurt true positives too much. Removing
  # it pushed true positives for most training counts above 80%, so the exclusivity
  # enforcement was removed until we find a better way to handle it.
  #
  class Classifier
    VERSION = 1
    # The minimum number of tokens an item needs into order to be classified.
    #
    MIN_TOKEN_COUNT = 50 unless defined?(MIN_TOKEN_COUNT)
    
    # Bias this controls the bias between positive and negative classifications.
    #
    # It does this by distorting the sizes of foreground and background pools.
    #
    # Values larger than 1 will move the bias towards positives, values smaller
    # than 1 will move the bias towards negatives.  The default is 1 which is no bias.
    BIAS = 1
  
    # Loads a Bayes object from a dumped version stored returned by Bayes#dump
    #
    def self.load(data, &init_block)
      begin
        bayes = Marshal.load(data)
        
        unless bayes.version == VERSION
          raise ArgumentError, "Serialized version (#{bayes.version}) did not match code version (#{VERSION})"
        else
          return bayes
        end        
      rescue Exception => error
        if block_given?
          self.new(&init_block)
        else
          raise error
        end
      end
    end
  
    # This class is used to store Pool data
    class Pool
      attr_reader :name, :tokens, :trained_uids
      attr_accessor :train_count, :token_count
    
      def initialize(name)
        @name = name
        @train_count = @token_count = 0
        @tokens = Hash.new(0.0)
        @trained_uids = Hash.new(0)
      end
    
      def to_s
        "<Bayes::PoolData @name='#{name}'>"
      end
    end
  
    EMPTY_POOL = Pool.new("empty") unless const_defined?(:EMPTY_POOL)
  
    # A PoolSpec is used to configure the classifier to use a specific pool
    # in foreground or background of the classification of any pool.  
    #
    # By default the classifier will use the pool itself for the foreground
    # and the foreground_union minus the pool for the background.  However,
    # when configuring the classifier you can add additional foreground and
    # background pools to be used as well.  You do this on initialization by 
    # adding instances of PoolSpec to the foreground_pool_specs or background_pool_specs
    # arrays for the classifier.
    # 
    class PoolSpec
      def initialize
        @pattern = @name = @description = nil
        yield(self) if block_given?

        raise ArgumentError, "Pattern must be specified." if @pattern.nil?
      end
      
      # This is the pattern to use to generate the name of the pool.
      # This pattern can be a plain string that will be used literally or
      # it can be a pattern using Ruby String substitions with the variable
      # pool_name in scope.  This allows you to create pool names derived
      # from the each pool that is going to be classified.
      #
      # For example, we can create a pattern '_!not_#{pool_name}' can get
      # resolve to the name of a pool that stores negative moderation for
      # each pool in the classifier.
      #
      # If the pool referenced by the PoolSpec does not exist, the classifier
      # will use a temporary empty pool in its place.
      #
      # This is a required option.
      attr_accessor :pattern
    
      # A simple textual name that can be used in UIs.
      attr_accessor :name
    
      # A simple textual description that can be used in UIs. (Optional)
      attr_accessor :description    
   
      # Gets name of the pool this spec refers to.
      def pool_name(pool_name)
        eval("\"#{pattern}\"")
      end
    end
  
    class ProbabilityOptions
       attr_accessor :only, :bias, :bias_hash, :include_evidence

       def initialize(options = {})
         @include_evidence      = (options[:include_evidence] == true)
         @bias                  = (options[:bias].nil? ? BIAS : (options[:bias].is_a?(Hash) ? BIAS : options[:bias]))
         @bias_hash             = (options[:bias].is_a?(Hash) ? options[:bias] : nil)
         @only                  = options[:only] ? Array(options[:only]) : nil
       end

       def to_hash
         {
           :include_evidence => @include_evidence,
           :bias => @bias,
         }
       end

       def ==(other)
         self.to_hash == other.to_hash
       end

       def inspect
         "<ProbabilityOptions: #{to_hash.inspect}"
       end
     end
   
    # Creates a instance of the Bayes Classifier.
    #
    # When a block is passed in, initialize will yield itself
    # to the block to allow initialization options to be set.
    #
    def initialize
      @version = VERSION
      @pools = {}    
      @fg_pool_cache = {}
      @bg_pool_cache = {}
    
      # Start with the default tokenizer
      @tokenizer = DefaultTokenizer.new
        
      # By default we don't ignore any pools
      @pools_to_ignore = []
    
      @foreground_pool_specs = []
      @background_pool_specs = []
      @pools_to_classify = nil
    
      @prob_cache = {}
      yield(self) if block_given?
    end
  
    attr_reader :pools, :version
  
    # Get or set the tokenizer
    attr_reader :tokenizer
  
    # Get or set the array of pool to ignore when classifying
    attr_accessor :pools_to_ignore
  
    # Array of PoolSpec to use as additional background pools for
    # classification
    #
    attr_reader :background_pool_specs
  
    # Array of PoolSpec to use as addition foreground pools for
    # classificaton
    #
    attr_reader :foreground_pool_specs
  
    # Ensures that any tokenizer responds to :tokens
    def tokenizer=(tokenizer)
      if tokenizer.respond_to?(:tokens_with_counts) and tokenizer.respond_to?(:tokens)
        @tokenizer = tokenizer
      else
        raise ArgumentError, "The tokenizer must respond to :tokens_with_counts and :tokens. #{tokenizer}"
      end
    end
  
    # Dumps a bayes instance to a form that can be reloaded using Bayes.load
    #
    def dump
      remove_instance_variable(:@foreground_union) if defined?(@foreground_union) # Remove old ivar
      @pools_to_classify = nil
      @fg_pool_cache = {}
      @bg_pool_cache = {}
      self.clear_prob_cache
      Marshal.dump(self)
    end
  
    # Trains the classifier on an item for a pool.
    #
    #  * pool_name - The name of the pool to train with the given item
    #  * item - The item to use to train the classifier. The item
    #           must be tokenizable by the current tokenizer.
    #
    def train(pool_name, item, uid)
      pool = get_pool(pool_name)
    
      if uid and pool.trained_uids[uid] > 0
        raise ArgumentError, "Cannot train a pool with an item more than once. Pool: #{pool_name}, uid: #{uid}"
      end
    
      pool.train_count += 1
      pool.trained_uids[uid] = 1
      
      @tokenizer.tokens_with_counts(item).each do |token, count|
        pool.tokens[token] += count
        pool.token_count += count
      end
    end
  
    # Untrains the classifier on a item for a pool.
    #
    #  * pool - The name of the pool to untrain with the given item.
    #  * item - The item to use to untrain the classifier. The item
    #           must be tokenizable by the current tokenizer
    #
    def untrain(pool_name, item, uid)
      pool = get_pool(pool_name)
    
      if uid and pool.trained_uids[uid] < 1
        raise ArgumentError, "Cannot untrain with item that has not been used in training. Pool: #{pool_name}, uid: #{uid}"
      end
    
      pool.train_count -= 1
      pool.trained_uids.delete(uid) if uid      
        
      @tokenizer.tokens_with_counts(item).each do |token, count|
        pool.tokens[token] -= count
        pool.token_count -= count
      end
        
      if pool.train_count <= 0
        remove_pool(pool_name)
      end
    end
  
    # Allows you to use the same options across multiple calls to the classifier.
    #
    # The options are parsed once to prevent multiple object creation for each call
    # to guess.
    #
    # Use it like so:
    #
    #    bayes.with_guess_options(:bais => 1.2) do |bayes|
    #      items.each do |item|
    #        bayes.guess(item)
    #      end
    #    end
    #
    def with_guess_options(options = {})    
      yield(GuessOptionsProxy.new(self, ProbabilityOptions.new(options))) if block_given?
    end
  
    class GuessOptionsProxy
      def initialize(bayes, options)
        @bayes = bayes
        @options = options
      end
    
      def guess(item, options = nil)
        if options
          raise ArgumentError, "Option merging is not supported with Bayes#with_guess_options"
        else
          @bayes.send(:guess, item, @options)
        end
      end
    
      def method_missing(method, *arguments, &block)
        puts "#{method}(#{arguments.join(', ')})"
        bayes.send(method, *arguments, &block)
      end
    end
  
    # Computes the probability that the item is in each of the trained pools
    #
    # * item - An item that can be tokenized by the current tokenizer.
    # * options - A Hash of options for the classification.
    #
    # Option can be one of the class level options, i.e. :max_discriminators,
    # :min_prob_strength, :unknown_word_strength, :unknown_word_prob
    # or :bias.  See the class level documentation for these.
    # 
    # In addition these options are also supported:
    # 
    # * <tt>only</tt>: A list of pool names to classify instance of all the pools.
    # * <tt>min_token_count</tt>: The minumum number of tokens an item needs in-order to be classified.
    # * <tt>min_train_count</tt>: The minimum number of trained instances a pool needs to be classified.
    # * <tt>include_evidence</tt>: If true the returned hash will contain
    #  an array for each pool with the first element being the probability
    #  and the second element being a Hash with token => prob elements
    #  for each token used to compute the final probability.
    #
    # The bias can also be provided as a hash in which the keys are pool names and the
    # value is the bias to use for that pool.  You can provide a default bias as
    # as the default for the hash, or Bayes.bias will be used if bias[pool_name] in nil.
    # 
    # Returns a Hash of the form {'pool_name' => prob} for each pool,
    # where pool_name is the name of the pool and prob is a float between
    # 0..1 that represents the probability that the item belongs to the class
    # identified by pool_name.
    #
    # This method uses chi2_prob to do most of the work.
    #
    def guess(item, options = {})      
      prob_options = options.is_a?(ProbabilityOptions) ? options : ProbabilityOptions.new(options || {})   
      guesses = {}
      tokens = @tokenizer.tokens(item)
    
      if tokens.size >= MIN_TOKEN_COUNT
        self.pools_to_classify.each do |pool|
          pool_name = pool.name
          # Skip if only was provided and the current pool is not in it
          next if prob_options.only and not(prob_options.only.include?(pool_name))

          # If we have per-pool biases, copy the bias from the hash to the bias attr
          if prob_options.bias_hash
            prob_options.bias = (prob_options.bias_hash[pool_name] or BIAS)
          end
        
          guesses[pool_name] = chi2_prob(tokens, 
                                         foreground_pools(pool_name), 
                                         background_pools(pool_name),
                                         @prob_cache[pool_name],
                                         prob_options)        
        end
      end
    
      guesses
    end
      
    # Returns the list of pool names the classifier has training data for.
    #
    def pool_names
      @pools.keys
    end
  
    # Returns the list of pools the classifier will classify after filtering
    # the list through pools_to_ignore
    def pools_to_classify
      unless @pools_to_classify
        @pools_to_classify = @pools.values.select do |pool|
          not @pools_to_ignore.detect do |ignore|
            ignore.is_a?(Regexp) ? (pool.name =~ ignore) : pool.name == ignore
          end
        end
      end
      @pools_to_classify
    end
    
    def clear_prob_cache
      @prob_cache.each do |tag, cache|
        @prob_cache[tag] = {}
      end
    end
  
    # Returns the train count for a named pool
    #
    def train_count(pool_name)
      (pool = @pools[pool_name]) ? pool.train_count : 0
    end
  
    private
    def get_pool(name)
      if @prob_cache[name].nil?
        @prob_cache[name] = Hash.new
      end
      @pools[name] or (@pools[name] = Pool.new(name))
    end
  
    def remove_pool(name)
      @pools.delete(name)
    end
    
    def background_pools(pool_name)
      unless background_pools = @bg_pool_cache[pool_name]
        background_pools = @bg_pool_cache[pool_name] = pools_from_specs(pool_name, background_pool_specs)
      end
    
      background_pools
    end
  
    def foreground_pools(pool_name)
      unless foreground_pools = @fg_pool_cache[pool_name]
        foreground_pools = [@pools[pool_name]]
        foreground_pools += pools_from_specs(pool_name, foreground_pool_specs)
        @fg_pool_cache[pool_name] = foreground_pools
      end
    
      foreground_pools
    end
  
    def pools_from_specs(pool_name, specs)
      specs.map do |spec|
        unless pool = @pools[spec.pool_name(pool_name)]
          pool = EMPTY_POOL
        end
        pool
      end
    end
  
    # We use Ruby Inline for compiling the C code.
    #
    # Realistically we aren't using a whole lot of RubyInline and
    # the amount of C code we have is probably larger that RubyLine
    # was intended to be used for - this results in fairly messy source.
    #
    # However, RubyInline does handle on demand compiliation nicely so thats
    # what we'll use it for.  At some later stage we might want to make this
    # compilation part of the gem installation or something, but for now this
    # works.
    #  
    inline do |builder|
      require 'rbconfig'
      Config::CONFIG['CFLAGS'].sub!('-O', '-O3') unless RUBY_PLATFORM =~ /darwin9.0/
      builder.prefix File.read(File.join(File.dirname(__FILE__), 'classifier.c'))
      builder.add_to_init <<-INIT
        rb_define_method(c, "chi2_prob", (VALUE(*)(ANYARGS))chi2_prob, -1);
        rb_define_method(c, "get_clues", (VALUE(*)(ANYARGS))get_clues, -1);
        rb_define_method(c, "probability", (VALUE(*)(ANYARGS))probability, -1);
      INIT
    end
    
    # Default tokenizer just splits strings
    class DefaultTokenizer
      def tokens(item)
        tokens_with_counts(item).keys
      end
    
      def tokens_with_counts(item)
        item.split.inject(Hash.new(0.0)) do |counts, token|
          counts[token] += 1
          counts
        end
      end
    end
    
    class IdentityTokenizer
      def tokens(item); item; end
      def tokens_with_counts(item); item; end
    end
  end
end