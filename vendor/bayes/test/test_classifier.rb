# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Override MIN_TOKEN_COUNT to simplify testing
module Bayes; class Classifier; MIN_TOKEN_COUNT = 2; end; end

require File.dirname(__FILE__) + '/test_helper'
gem 'mocha'
require 'mocha'

class ClassifierTest < Test::Unit::TestCase
    
  def test_block_initialization
    bayes = Bayes::Classifier.new do |bayes|
      bayes.pools_to_ignore = ['seen', /\*.*/]
    end
    
    assert_equal ['seen', /\*.*/], bayes.pools_to_ignore
  end
  
  def test_block_initialization_with_invalid_tokenizer
    assert_raise(ArgumentError) do
      Bayes::Classifier.new do |bayes|
        bayes.tokenizer = self
      end
    end
  end
  
  def test_default_tokenizer
    tokenizer = Bayes::Classifier::DefaultTokenizer.new
    assert_equal({'Test' => 2, 'text' => 1}, tokenizer.tokens_with_counts('Test Test text'))
    assert_equal(%w(Test text).sort, tokenizer.tokens("Test Test text").sort)
  end
  
  def test_train_calls_tokenizers_tokens_with_counts_method
    tokenizer = stub(:tokens => [])
    tokenizer.expects(:tokens_with_counts).with('Some').returns({'Some' => 1})    
    bayes = Bayes::Classifier.new {|b| b.tokenizer = tokenizer}
    bayes.train('pool', "Some", "1")
  end
  
  def test_untrain_calls_tokenizers_tokens_with_counts_method
    tokenizer = stub(:tokens => [])
    tokenizer.expects(:tokens_with_counts).with('Some').returns({'Some' => 1}).times(2)
    bayes = Bayes::Classifier.new {|b| b.tokenizer = tokenizer}
    bayes.train('pool', "Some", "1")
    bayes.untrain('pool', "Some", "1")
  end
  
  def test_guess_calls_tokenizers_tokens_with_counts_method
    tokenizer = stub(:tokens_with_counts => {})
    tokenizer.expects(:tokens).with('Some').returns(['Some']) 
    bayes = Bayes::Classifier.new {|b| b.tokenizer = tokenizer}
    bayes.guess("Some")
  end
  
  def test_custom_tokenizer
    tokenizer = mock()
    tokenizer.expects(:tokens_with_counts).with('Some text to tokenize.').returns({'Some' => 1})
    tokenizer.expects(:tokens_with_counts).with('Some more text').returns({'more' => 1}).times(2)
    tokenizer.expects(:tokens).with('Text to classify').returns(%w(Text to classify))
    
    bayes = Bayes::Classifier.new do |bayes|
      bayes.tokenizer = tokenizer
    end
    
    bayes.train('pool', 'Some text to tokenize.', '1')
    bayes.train('pool', 'Some more text', '2')
    bayes.untrain('pool', 'Some more text', '2')
    bayes.guess('Text to classify')
  end
  
  def test_training_creates_pool
    bayes = Bayes::Classifier.new
    assert bayes.pool_names.empty?
    bayes.train('newpool', 'This is some text on which to train.', '1')
    assert_equal ['newpool'], bayes.pool_names
  end
  
  def test_pools_to_classify
    bayes = Bayes::Classifier.new do |bayes|
      bayes.pools_to_ignore = ['bg', /\*.*/]
    end
    
    bayes.train('bg', 'text', '1')
    bayes.train('fg', 'text', '2')
    bayes.train('*special', 'text', '3')
    
    assert_equal [bayes.pools['fg']], bayes.pools_to_classify
  end
  
  def test_untraining_removes_pool
    bayes = Bayes::Classifier.new
    bayes.train('newpool', 'This is some text on which to train.', '1')
    assert_equal ['newpool'], bayes.pool_names
    bayes.untrain('newpool', 'This is some text on which to train.', '1')
    assert bayes.pool_names.empty?
  end
  
  def test_training_increments_token_counts
    bayes = Bayes::Classifier.new
    bayes.train('pool', 'This is some text. It is plain text.', '1')
    assert bayes.pools['pool']
    
    pool = bayes.pools['pool']
    assert_equal 1, pool.train_count
    assert_equal 8, pool.token_count
    assert_equal 2, pool.tokens['is']
    assert_equal 2, pool.tokens['text.']
    assert_equal 1, pool.tokens['some']
  end
  
  def test_training_prevents_training_the_same_item_more_than_once_per_pool
    bayes = Bayes::Classifier.new
    bayes.train('pool', 'This is some text', 'id1')
    bayes.train('other', 'This is some text', 'id1')
    assert_raise(ArgumentError) {bayes.train('pool', 'This is some text', 'id1')}
  end
  
  def test_untraining_prevents_untraining_non_existant_uid
    bayes = Bayes::Classifier.new
    bayes.train('pool', 'This is some text', 'id1')
    
    assert pool = bayes.pools['pool']
    assert_equal 1, pool.train_count
    assert_equal 4, pool.token_count
    assert_equal 1, pool.tokens['This']
    assert_equal 1, pool.tokens['is']
    assert_equal 1, pool.tokens['some']
    assert_equal 1, pool.tokens['text']
    
    assert_raise(ArgumentError) {bayes.untrain('pool', 'This is some text', 'id2')}
    
    assert pool = bayes.pools['pool']
    assert_equal 1, pool.train_count
    assert_equal 4, pool.token_count
    assert_equal 1, pool.tokens['This']
    assert_equal 1, pool.tokens['is']
    assert_equal 1, pool.tokens['some']
    assert_equal 1, pool.tokens['text']
  end
  
  def test_untraining_decrements_token_counts
    bayes = Bayes::Classifier.new
    bayes.train('pool', 'This is some text. It is plain text.','1')
    bayes.train('pool', 'Some text. It will be untrained.', '2')
    
    pool = bayes.pools['pool']
    assert_equal 2, pool.train_count
    assert_equal 14, pool.token_count
    assert_equal 2, pool.tokens['It']
    assert_equal 3, pool.tokens['text.']
    assert_equal 1, pool.tokens['This']
    assert_equal 1, pool.tokens['untrained.']
    
    bayes.untrain('pool', 'Some text. It will be untrained.', '2')
    assert_equal 1, pool.train_count
    assert_equal 8, pool.token_count
    assert_equal 1, pool.tokens['It']
    assert_equal 2, pool.tokens['text.']
    assert_equal 1, pool.tokens['This']
    assert_equal 0, pool.tokens['untrained']
  end
  
  def test_can_train_untrain_and_train_again
    bayes = Bayes::Classifier.new
    bayes.train('pool1', 'Test', '1')
    bayes.train('pool1', 'Test', '2')
    bayes.untrain('pool1', 'Test', '1')
    bayes.train('pool1', 'Test', '1')
  end
  
  def test_guess_returns_probabilities_for_each_pool
    bayes = Bayes::Classifier.new
    bayes.train('pool1', 'Here is pool1.', '1')
    bayes.train('pool2', 'Here is pool2.', '2')
    
    guesses = bayes.guess('Here is pool1.')
    assert_equal ['pool1', 'pool2'], guesses.keys.sort
  end
  
  def test_guess_ignores_non_classified_pools
    bayes = Bayes::Classifier.new do |bayes|
      bayes.pools_to_ignore << 'bg'
    end
    bayes.train('pool1', 'Here is pool1.', '1')
    bayes.train('pool2', 'Here is pool2.', '2')
    bayes.train('bg', 'Here is bg.', '3')
    
    guesses = bayes.guess('Here is bg.')
    assert_equal ['pool1', 'pool2'], guesses.keys.sort
  end
  
  def test_guess_ignores_items_without_enough_tokens
    bayes = Bayes::Classifier.new
    bayes.train('pool1', 'Here is pool1.', '1')
    bayes.train('pool2', 'Here is pool2.', '2')
    bayes.train('bg', 'Here is bg.', '3')

    assert_not_equal({}, bayes.guess("enough text to classifiy"))
    assert_equal({}, bayes.guess("not-enough"))
  end
  
  def test_probability_raises_argument_error_for_non_existant_pool
    bayes = Bayes::Classifier.new
    assert_raises(ArgumentError) {bayes.probability('foo', 'token')}
  end
  
  def test_pool_spec_with_pattern
    spec = Bayes::Classifier::PoolSpec.new do |spec|
      spec.pattern = '_!not_#{pool_name}'
    end
    
    assert_equal '_!not_pool1', spec.pool_name('pool1')
  end
  
  def test_pool_spec_with_name
    spec = Bayes::Classifier::PoolSpec.new do |spec|
      spec.pattern = 'background'
    end
    
    assert_equal 'background', spec.pool_name('pool1')
  end
  
  def test_should_pass_in_negative_pool_when_configured_with_negative_pool_pattern
    bayes = Bayes::Classifier.new do |bayes|
      bayes.pools_to_ignore = [/_!not_.*/]
      bayes.background_pool_specs << Bayes::Classifier::PoolSpec.new do |spec|
        spec.pattern = '_!not_#{pool_name}'
      end
    end
    
    bayes.train('pool1', 'text', '1')
    bayes.train('_!not_pool1', 'text', '1')

    bayes.expects(:chi2_prob).with('text classify'.split, [bayes.pools['pool1']], 
                                             [bayes.pools['_!not_pool1']], {},
                                             Bayes::Classifier::ProbabilityOptions.new)
                                    
    bayes.guess('text classify')
  end
  
  def test_probability_with_arbitrary_pools_when_fg_and_bg_make_up_complete_corpus
    bayes = Bayes::Classifier.new    
    fg_pools = [make_mock_pool('token', 2.0, 4.0)]
    bg_pools = [make_mock_pool('token', 1.0, 4.0)]
    prob = bayes.probability('token', fg_pools, bg_pools, Bayes::Classifier::ProbabilityOptions.new)
    
    # This was calculated manually, a bit fragile, but not really any better way to do it
    assert_in_delta(0.644927536231884, prob, 2 ** -20)
  end
  
  def test_probability_with_arbitrary_pools_without_separate_bg
    bayes = Bayes::Classifier.new    
    fg_pools = [make_mock_pool('token', 2.0, 4.0)]
    bg_pools = []
    prob = bayes.probability('token', fg_pools, bg_pools,  Bayes::Classifier::ProbabilityOptions.new)
    
    # This was calculated manually, a bit fragile, but not really any better way to do it
    assert_in_delta(0.763157894736842, prob, 2 ** -20)
  end
  
  def test_probability_with_arbitrary_pools_with_mutliple_backgrounds
    bayes = Bayes::Classifier.new
    fg_pools = [make_mock_pool('token', 2.0, 4.0)]
    bg_pools = [make_mock_pool('token', 1.0, 4.0), make_mock_pool('token', 1.0, 6.0)]
    prob = bayes.probability('token', fg_pools, bg_pools, Bayes::Classifier::ProbabilityOptions.new)    
    assert_in_delta(0.691137462942737, prob, 2 ** -20)
  end
    
  def test_probability_doesnt_change_with_empty_additional_background_pool
    bayes = Bayes::Classifier.new
    bayes.train('test', 'test', '1')
    bayes.train('test2', 'test', '1')
    bayes.train('test2', 'test', '2')
    
    original = bayes.guess('test')
    
    bayes.background_pool_specs << Bayes::Classifier::PoolSpec.new do |s|
      s.pattern = '!!#{pool_name}'
    end
    
    assert_equal original, bayes.guess('test')
  end
  
  def test_guess_ignores_pools_to_ignore_by_pattern
    bayes = Bayes::Classifier.new do |bayes|
      bayes.pools_to_ignore = ['bg', /^\*.*/]
    end
    bayes.train('pool1', 'Here is pool1.', '1')
    bayes.train('pool2', 'Here is pool2.', '2')
    bayes.train('bg', 'Here is bg.', '3')
    bayes.train('*ignore', 'Here is ignore.', '2')
    
    guesses = bayes.guess('Here is bg.')
    assert_equal ['pool1', 'pool2'], guesses.keys.sort
  end
  
  def test_guess_returns_result_hash
    bayes = Bayes::Classifier.new
    
    bayes.train('pool1', 'this is pool1', '1')
    bayes.train('pool2', 'this is pool2', '2')
    
    results = bayes.guess('this is this is')
    assert results.is_a?(Hash), "Result is not a hash"
    assert results['pool1'].is_a?(Float), "Result for pool1 is not a float: #{results['pool1']}"
    assert results['pool2'].is_a?(Float), "Result for pool2 is not a float: #{results['pool2']}"
  end
  
  def test_guess_probabilities_all_between_0_and_1
    bayes = Bayes::Classifier.new
    
    bayes.train('pool1', 'this is pool1', '1')
    bayes.train('pool2', 'this is pool2', '2')
    
    results = bayes.guess('this is this is')
    assert results.is_a?(Hash), "Result is not a hash"
    assert((0.0..1.0).include?(results['pool1']), "Result for pool1 is outside 0 - 1 : #{results['pool1']}")
    assert((0.0..1.0).include?(results['pool2']), "Result for pool2 is outside 0 - 1 : #{results['pool1']}")
  end
  
  def test_get_clues_only_returns_max_discriminator_clues
    bayes = Bayes::Classifier.new
    bayes.train('fg', 'fg_only both', '1')
    bayes.train('bg', 'bg_only both', '2')
    
    expected_clues = ['fg_only', 'bg_only']
    
    clues = bayes.get_clues(%w(fg_only bg_only) + (['both'] * 150) , [bayes.pools['fg']], [bayes.pools['bg']], {}, Bayes::Classifier::ProbabilityOptions.new)
    assert_equal expected_clues, clues.flatten.select{|o| o.is_a? String}
  end
  
  def test_get_clues_ignores_probs_less_than_min_prob_strength
    bayes = Bayes::Classifier.new
    bayes.train('fg', 'fgonly both', '1')
    bayes.train('bg', 'bgonly both', '2')
        
    expected_clues = ['fgonly', 'bgonly']
    clues = bayes.get_clues(%w(fgonly bgonly both), [bayes.pools['fg']], [bayes.pools['bg']], {}, Bayes::Classifier::ProbabilityOptions.new)
    assert_equal expected_clues, clues.flatten.select{|o| o.is_a? String}
  end
  
  def test_get_clues_returns_unknown_word_prob_for_unknown_words
    bayes = Bayes::Classifier.new
    bayes.train('pool', 'this is text', '1')
      
    assert_equal 0.5, bayes.probability('unknown', [bayes.pools['pool']], [], Bayes::Classifier::ProbabilityOptions.new)
  end
  
  def test_guess_with_evidence_includes_evidence
    bayes = Bayes::Classifier.new
    bayes.train('pool1', 'This is text', '1')
    bayes.train('pool2', 'This is other text', '2')
    
    results = bayes.guess('This other', :include_evidence => true)
    assert results.is_a?(Hash)
    assert results['pool1'].is_a?(Array)
    assert results['pool1'].last.is_a?(Array)
  end
  
  def test_default_bias
    bayes = Bayes::Classifier.new
    bayes.expects(:chi2_prob).with do |*args|
      args.last.bias == Bayes::Classifier::BIAS
    end.times(2)
    bayes.train('pool1', "This is some text", "1")
    bayes.train('pool2', "This is some text", "1")
    bayes.guess("some text")
  end
  
  def test_overall_bias
    bayes = Bayes::Classifier.new
    bayes.expects(:chi2_prob).with do |*args|
      args.last.bias == 1.1
    end.times(2)
    bayes.train('pool1', "This is some text", "1")
    bayes.train('pool2', "This is some text", "1")
    bayes.guess("some text", :bias => 1.1)
  end
  
  def test_per_tag_bias
    bayes = Bayes::Classifier.new
    bayes.expects(:chi2_prob).with do |*args|
      args[1] == [bayes.pools['pool1']] and args.last.bias == 1.1
    end
    bayes.expects(:chi2_prob).with do |*args|
      args[1] == [bayes.pools['pool2']] and args.last.bias == 1.2
    end
    bayes.train('pool1', "This is some text", "1")
    bayes.train('pool2', "This is some text", "1")
    bayes.guess("some text", :bias => {'pool1' => 1.1, 'pool2' => 1.2})
  end
    
  def test_per_tag_bias_uses_default_when_missing
    bayes = Bayes::Classifier.new
    bayes.expects(:chi2_prob).with do |*args|
      args[1] == [bayes.pools['pool1']] and args.last.bias == 1.1
    end
    bayes.expects(:chi2_prob).with do |*args|
      args[1] == [bayes.pools['pool2']] and args.last.bias == Bayes::Classifier::BIAS
    end
    bayes.train('pool1', "This is some text", "1")
    bayes.train('pool2', "This is some text", "1")
    bayes.guess("some text", :bias => {'pool1' => 1.1})
  end
  
  def test_dump_and_load
    bayes = Bayes::Classifier.new
    bayes.train('pool', 'This is some text. It is plain text.', '1')
    assert bayes.pools['pool']

    pool = bayes.pools['pool']
    assert_equal 1, pool.train_count
    assert_equal 8, pool.token_count
    assert_equal 2, pool.tokens['is']
    assert_equal 2, pool.tokens['text.']
    assert_equal 1, pool.tokens['some']
    
    dump = bayes.dump
    new_bayes = Bayes::Classifier.load(dump)
   
    assert bayes.pools['pool']
    pool = bayes.pools['pool']
    assert_equal 1, pool.train_count
    assert_equal 8, pool.token_count
    assert_equal 2, pool.tokens['is']
    assert_equal 2, pool.tokens['text.']
    assert_equal 1, pool.tokens['some']
  end
    
  def test_only_guess_named_tags
    bayes = Bayes::Classifier.new
    bayes.train('pool1', 'This is some text', '1')
    bayes.train('pool2', 'This is some text', '2')
    bayes.train('pool3', 'This is some text', '3')
    
    assert_equal ['pool1'], bayes.guess('This is some text', :only => 'pool1').keys.sort
    assert_equal ['pool1', 'pool2'], bayes.guess('This is some text', :only => ['pool1', 'pool2']).keys.sort
  end
  
  def test_load_returns_classifier
    assert_instance_of(Bayes::Classifier, Bayes::Classifier.load(Bayes::Classifier.new.dump))
  end
  
  def test_load_with_nil_uses_block_initialization
    bayes = Bayes::Classifier.load(nil) do |bayes|
      bayes.pools_to_ignore << 'test'
    end
    
    assert_equal ['test'], bayes.pools_to_ignore
  end
  
  def test_load_with_invalid_data_uses_block_initialization
    bayes = Bayes::Classifier.load('foobar') do |bayes|
      bayes.pools_to_ignore << 'test'
    end
    
    assert_equal ['test'], bayes.pools_to_ignore
  end
  
  def test_load_with_valid_stream_doesnt_call_block
    bayes_dump = Bayes::Classifier.new.dump
    bayes = Bayes::Classifier.load(bayes_dump) do |bayes|
      flunk("Bayes.dump should not yield when a valid dumped Bayes instance is provided.")
    end
  end  
  
  def test_load_with_older_version_fails
    bayes = Bayes::Classifier.new
    bayes.instance_variable_set(:@version, Bayes::Classifier::VERSION - 1)
    assert_raise(ArgumentError) { Bayes::Classifier.load(bayes.dump) }
  end
  
  def test_load_with_newer_version_fails
    bayes = Bayes::Classifier.new
    bayes.instance_variable_set(:@version, Bayes::Classifier::VERSION + 1)
    assert_raise(ArgumentError) { Bayes::Classifier.load(bayes.dump) }
  end
  
  def test_load_without_version_fails
    bayes = Bayes::Classifier.new
    bayes.send(:remove_instance_variable, :@version)
    assert_raise(ArgumentError) { Bayes::Classifier.load(bayes.dump) }
  end
  
  def test_load_with_bad_version_calls_block
    bayes = Bayes::Classifier.new
    bayes.instance_variable_set(:@version, Bayes::Classifier::VERSION - 1)
    yielded = nil
    bayes = Bayes::Classifier.load(bayes.dump) do |bayes|
      yielded = bayes
    end
    assert_same(bayes, yielded)
  end
    
  # Tests to ensure that the classifier works with atomized tokens
  
  def test_train_with_atoms
    atomizing_tokenizer = stub(:tokens => [])
    atomizing_tokenizer.expects(:tokens_with_counts).with("this is text").returns({1 => 1, 2 => 1, 3 => 1})
    
    bayes = Bayes::Classifier.new do |b|
      b.tokenizer = atomizing_tokenizer
    end
    
    bayes.train('pool', "this is text", '1')
    assert_equal([1, 2, 3], bayes.pools['pool'].tokens.keys.sort)
  end
  
  def test_guess_with_atoms
    atomizing_tokenizer = mock(:tokens_with_counts => {})
    atomizing_tokenizer.expects(:tokens).with("this is text").returns([1, 2, 3])
    
    bayes = Bayes::Classifier.new do |b|
      b.tokenizer = atomizing_tokenizer
    end
    
    bayes.train('pool', "this is text", '1')
    assert_instance_of(Hash, bayes.guess('this is text'))
  end
  
  def test_with_options_uses_options_passed_in
    # This ensures that the probability options are only created once    
    prob_options = Bayes::Classifier::ProbabilityOptions.new(:bias => 1.2)
    Bayes::Classifier::ProbabilityOptions.expects(:new).with(:bias => 1.2).returns(prob_options)
        
    bayes = Bayes::Classifier.new 
    bayes.train('pool', 'this is text', '1')
    bayes.train('pool2', 'this is text', '2')
    bayes.expects(:chi2_prob).times(4).with do |*args|
      args.last == prob_options
    end
    
    bayes.with_guess_options(:bias => 1.2) do |bayes|
      bayes.guess("this is text")
      bayes.guess("this is text")
    end
  end
  
  def test_passing_options_within_with_guess_options_block_is_not_allowed
    bayes = Bayes::Classifier.new
    bayes.with_guess_options() do |bayes|
      assert_raise(ArgumentError) { bayes.guess("text", :bias => 1.2) }
    end
  end
  
  private
  def make_mock_pool(token, frequency, total)
    pool = Bayes::Classifier::Pool.new('test')
    pool.tokens[token] = frequency
    pool.token_count = total
    pool
  end
end
