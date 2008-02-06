# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'set'
require 'cv/array_ext'
require 'cv/taggable'
require 'cv/tagging'
require 'cv/taggable_tokenizer'
require 'bayes'
require 'analysis'

# This should eventually be moved to the classifier plugin.
#
class CrossValidation # :nodoc:
  RANDOM_BACKGROUND_SIZE = 500
  include Analysis
  @@tags_to_skip = ['duplicate']
  
  attr_reader :seed, :folds, :limit, :comment
  
  def initialize(options = {})
    require 'progressbar'
    options = {:folds => 10, 
               :comment => 'no comment', 
               :seed => Time.now.to_i,
               :positive_cutoff => 0.9,
               :negative_cutoff => 0.9}.merge(options.delete_if {|key, value| value.nil?})
    
    @corpus = options[:corpus]
    @tagger = options[:tagger]
    
    if @corpus.nil? or not(File.exist?(@corpus))
      raise ArgumentError, "#{@corpus} directory does not exist."
    end
    
    if @tagger.nil?
      raise ArgumentError, "You must provide a tagger with tagger=<taggername>"
    end

    # Setup some caches for commonly accessed items
    @taggables = Taggable.find(@corpus)
    @taggables_by_id = @taggables.hash_by(:taggable_id)
    @taggings = Tagging.load_for_tagger(@corpus, @tagger)
    @taggings_by_taggable_id = @taggings.non_unique_hash_by(:taggable_id)
    @tagging_strengths = @taggings.inject(Hash.new) {|h, t| h["#{t.tag}-#{t.taggable_id}"] = t.strength; h}
    @tags = @taggings.inject(Set.new) {|set, tagging| set << tagging.tag; set}
    
    @positive_cutoff = options[:positive_cutoff].to_f
    @negative_cutoff = options[:negative_cutoff].to_f
    @ranges = {:pos => (@positive_cutoff..1.0), 
               :neg => (0.0..@negative_cutoff), 
               :unk => (@negative_cutoff..@positive_cutoff)}
    @seed = options[:seed]
    @folds = options[:folds]
    @limit = options[:limit]
    @comment = options[:comment]
    @errors = []
    @classifier_options = (options[:classifier_options] or {})
    
    @tokenizer = TaggableTokenizer.new(@corpus)
  end
  
  def execute(result_directory, progress_io = STDERR)
    cv_runs = 0
    results = {}
    tokens = {}
    
    item_subsets = build_subsets(folds.to_i, seed)

    progress_io.puts "Doing cross validations for #{@tagger} with #{item_subsets.size}" +
                          " sets of approximately #{item_subsets.first.size} items."
            
    # Now do N tests using a different test set each time
    item_subsets.size.times do |i|
      test_set = item_subsets[i]
      training_set = item_subsets.dup
      training_set.delete(test_set)
      training_set.flatten!
      progress_bar = ProgressBar.new("#{@tagger} CV #{i+1}", test_set.size + training_set.size + 1000, progress_io)
      
      cv_results, cv_tokens = cross_validate(training_set, test_set, progress_bar)
      
      cv_results.each do |user_tag, result|
        results[user_tag] ||= []
        results[user_tag] << result
      end
      
      tokens[@tagger] ||= []
      tokens[@tagger] += cv_tokens
      
      cv_runs += 1
      progress_bar.finish
    end
    
    execution_details = {
      :id => File.basename(result_directory),
      :subversion_url => get_svn_url,
      :subversion_revision => get_svn_revision,
      :date => Time.now.to_s,
      :seed => seed.to_s,
      :folds => @folds,
      :number_of_feed_items => @taggables.size,
      :cv_runs => cv_runs,
      :comment => comment,
      :positive_cutoff => @positive_cutoff,
      :negative_cutoff => @negative_cutoff,
      :tags_to_ignore => @tags_to_ignore,
      :classifier_options => Bayes::Classifier::ProbabilityOptions.new(@classifier_options).to_hash.update(:rnd_bg_size => RANDOM_BACKGROUND_SIZE)
    }
    save_results(result_directory, execution_details, results, tokens, @errors, progress_io)
  end
    
  private
  def get_svn_revision
    if `svn info` =~ /Revision: (.*)$/
      $1
    end
  end
  
  def get_svn_url
    if `svn info` =~ /URL: (.*)$/
      $1
    end
  end
  
  # Builds subsets of the feed item ids, only creates subset for a given user scope, i.e. only items that user has tagged
  def build_subsets(folds, seed)
    require 'set'
    srand(seed)
    @taggings.inject(Set.new) do |set, tagging|
      set << tagging.taggable_id
      set
    end.to_a.shuffle / folds
  end
  
  # Does the actual cross validation
  #
  # The cross validator will pass every tagging on each training item
  # to the train method of the classifier.  It is then up to the classifier
  # as to how to handle the tagging.
  #
  # = Inputs
  #   - training_set - The ids of feed items to train on
  #   - test_set - The ids of feed_items to test on
  #   - The user for scoping of the taggings
  #   - The progress bar to report progress to
  #
  # = As described in ticket 264, this was changed to operate over a single
  #   classifier per user that is trained on all their taggings.
  #
  def cross_validate(training_set, test_set, progress_bar)
    classifier = create_classifier(@tokenizer)
    
    # do the training
    
    # First train a random background of 500 items
    @taggables.sort_by{rand}.first(RANDOM_BACKGROUND_SIZE).each do |taggable|
      classifier.train(RANDOM_BACKGROUND, taggable, taggable.taggable_id)
      progress_bar.inc
    end
    
    # For every item in the training set
    training_set.each do |taggable_id|
      # if it has a tagging
      if @taggings_by_taggable_id[taggable_id]
        # train them on the taggings on the item
        @taggings_by_taggable_id[taggable_id].each do |tagging|
          # skip if it is in the tags_to_skip list
          next if @@tags_to_skip.include?(tagging.tag)
          
          if @taggables_by_id[taggable_id].nil?
            raise "No taggable for #{taggable_id} in #{@taggables_by_id.inspect}"
          end
          
          classifier.train(pool_name_for(tagging), @taggables_by_id[taggable_id], taggable_id)
        end
      end
      
      progress_bar.inc
    end
    
    # Set up the hash in which to store the results
    results = Hash.new
    classifier.pools_to_classify.each do |pool|
      results["#{@tagger}-#{pool.name}"] =  {:false_positive => 0, :false_negative => 0, 
                                               :true_positive => 0, :true_negative => 0, 
                                               :unknown => 0, :true_unknown => 0,
                                               :train_count => pool.train_count,
                                               :pool_size => pool.token_count}
    end
    
    # now do the classification of the test set, scoring each classification
    test_set.each do |taggable_id|        
      guesses = classifier.guess(@taggables_by_id[taggable_id], @classifier_options)
      
      guesses.each do |tag, prob|
        # skip it if the tag is in the tags to skip list
        @@tags_to_skip.include?(tag)
        # skip it if the tag is in the tags to ignore list
        next if TAGS_TO_IGNORE.include?(tag)
        # skip it if the classifier has never been trained on the tag
        next unless classifier.pool_names.include?(tag)
           
        tagging_strength = @tagging_strengths["#{tag}-#{taggable_id}"] 
        score =  score(tagging_strength, guesses[tag])
      
        results["#{@tagger}-#{tag}"][score] += 1
        
        # if the score was incorrect - record the item, tag, user and guess
        if score == :false_positive or score == :false_negative or score == :unknown
          @errors << {
            :item => taggable_id,
            :tag => tag,
            :user => @tagger,
            :user_tag => tagging_strength,
            :score => score,
            :guess => guesses[tag],
            :train_count => classifier.train_count(tag)
          }
        end
      end
      
      progress_bar.inc
    end        
  
    # Add the tokens to the results
    results = [results, classifier.foreground_union.tokens.keys]
        
    results
  end
  
  # This method is for cross validation purposes only.
  #
  # It takes an original tagging strength and a guessed strength and
  # comes up with a score which is one of :true_positive, :true_negative,
  # :false_positive, :false_negative, :true_unknown or :unknown.
  #
  def score(tagging_strength, guess)
    # If the tagging_strength is nil we should get a negative tag since that is how we treat them in training
    if tagging_strength.nil?
      if @ranges[:pos].include? guess
        :false_positive
      elsif @ranges[:neg].include? guess
        :true_negative
      else
        :unknown
      end
    elsif tagging_strength == 1
      if @ranges[:pos].include? guess
        :true_positive
      elsif @ranges[:neg].include? guess
        :false_negative
      else
        :unknown
      end
    elsif tagging_strength == 0
      if @ranges[:neg].include? guess
        :true_negative
      elsif @ranges[:pos].include? guess
        :false_positive
      else
        :unknown
      end
    else
      :unknown
    end
  end
  
  # Saves the results in YAML files in the result directory
  def save_results(result_directory, execution_details, results, tokens, errors, screen)    
    # now save the results in the result directory
    summaries = {}
    results.each do |name, results|
      output = {:execution_details => execution_details}
      output[:summary] = results.inject(Hash.new(0)) do |summary, result|
        result.keys.each do |key|
          summary[key] += result[key] unless result[key].nil?
        end
        summary
      end
            
      output[:results] = results
      File.open(File.join(result_directory, name + '.yaml'), 'w') do |f|
        f.write output.to_yaml
      end
      
      # save the summary for aggregation at a higher level
      summaries[name] = output[:summary]
    end
    
    # now aggregate and save the summaries
    summary = summaries.inject(Hash.new(0)) do |summary, result|
      result[1].keys.each do |key|
        summary[key] += result[1][key] unless result[1][key].nil?
      end
      summary
    end
        
    # Compute summary statistics - These are all taken from Pete's comments.
    #    Which reference  Fawcett, T. (2003). ROC Graphs: Notes and practical considerations for
    #                             researchers. Tech Report HPL-2003-4, HP Laboratories
    summary[:total_positives] = summary[:true_positive] + summary[:false_negative]
    summary[:total_negatives] = summary[:true_negative] + summary[:false_positive]
    summary[:total_classifications] = summary[:total_negatives] + summary[:total_positives] + summary[:unknown] + summary[:true_unknown]
    summary[:false_positive_rate] = summary[:false_positive].to_f / summary[:total_negatives]
    summary[:true_positive_rate] = summary[:true_positive].to_f / summary[:total_positives]
    summary[:false_negative_rate] = summary[:false_negative].to_f / summary[:total_positives]
    summary[:true_negative_rate] = summary[:true_negative].to_f / summary[:total_negatives]
    summary[:accuracy] = (summary[:true_positive] + summary[:true_negative]).to_f / (summary[:total_positives] + summary[:total_negatives])
    summary[:precision] = summary[:true_positive].to_f / (summary[:true_positive] + summary[:false_positive])
    summary[:recall] = summary[:true_positive].to_f / summary[:total_positives] 
    
    summary[:execution_details] = execution_details
    
    File.open(File.join(result_directory, 'summary.yaml'), 'w') do |f|
      f.write summary.to_yaml
    end
    
    # Save the token lists
    tokens.each do |user, token_list|
      File.open(File.join(result_directory, "#{user}-tokens.txt"), 'w') do |f|
        f.write "# #{summary[:execution_details][:comment]}\n"
        f.write Set.new(token_list).sort.to_a.join("\n")
      end
    end
    
    # Now save the errors in errors.yaml
    File.open(File.join(result_directory, 'errors.yaml'), 'w') do |f|
      f.write errors.to_yaml
    end
    
    screen.puts "Summary Results: (See #{result_directory} for more detail)"
    screen.puts summary.to_yaml
  end
end
