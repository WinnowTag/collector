# Copyright (c) 2007 The The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'cv/cross_validation'
require 'cv/train_count_report'

namespace :cv do
  
  desc "Prints a help message"
  task :help do
    puts <<-END_HELP
= Winnow cross validation tools =

This tools will execute cross validation (CV) over a moderated corpus.

== Executing CV ==

To execute cross validation you first need to have imported the moderated
corpus into a local installation of Winnow.  There are Rake tasks to assist
with this, execute {{{rake corpus:help}}} for more details.

To start a CV run you call the cv execute task.  To use a moderated corpus
you also need to set the Rails environment to 'evaluation' and set the 
required corpus database using the EVAL_DB variable.  For example,

{{{
  rake cv:execute RAILS_ENV=evaluation EVAL_DB=eval_seangeo_peerworks_org
}}}

will execute CV using the {{{eval_seangeo_peerworks_org}}} database.

During the execution, the FeedItems are divided into N subsets, or folds.
For each subset, the classifier is trained on the users taggings for each 
of the other folds for each <User,Tag> pair.  The classifier is then tested
on the hold out fold and it's results compared against the user moderation.

=== Additional Options for CV ===

  folds::
    The number of folds of feed items to produce.  Default is 10.
  
  seed::
    The number to seed to random number generator with. The default is
    to generate a seed and store it in {{{.seed}}}.  If {{{.seed}}} exists
    the number stored in it will be used to seed rand.  This ensures that
    item subset division is stable between CV executions.  You can reset the
    saved seed by calling {{{rake cv:reset_seed}}} or deleting the {{{.seed}}}
    file.
    
  limit::
    This will limit the number of feed items used in the CV. The default is to
    use all feed items.  This should be used with care as it will impact the
    validity of the results.
    
  comment::
    This will embed a comment in the summary file of the results of the CV.
    Might be useful for tracking changes done to the classifier across tests.
    
  positive_cutoff::
    This defines the cutoff point for positive taggings.  If the guess is above
    this value it will be scored as a positive guess.  Defaults to 0.7.
    
  negative_cutoff::
    This defines the cutoff point for negative taggings.  If the guess is below
    this value it will be scored as a negative guess. Defaults to 0.3.
  
  bias::
    Passed to the classifier.
    
  uws::
    Passed to the classifier as unknown_word_strength.
    
  uwp::
    Passed to the classifier as unknown_word_prob.
    
  max_discriminators::
    Passed to the classifier.
    
  min_prob_strength::
    Passed to the classifier.

== Results ==

The results of CV executions are stored in the {{{cv_results}}} directory. Each
execution will be stored in a new subdirectory of {{{cv_results}}}.  Within each 
subdirectory there is a YAML file for each <User,Tag> pair containing the results
off each CV run and the summary over all CV runs for that pair.  There is also a
summary.yaml file containing aggregated results for all N runs across all 
<User,Tag> pairs.

The values stored are:

  true_positive (TP)::
    The number of times a classifier applied a tag positively that coincided 
    with the human applied tag.
  true_negative (TN)::
    The number of times a classifier applied a tag negatively that coincided 
    with the human applied tag.
  false_positive (FP)::
    The number of times a classifier applied a tag positively when the human 
    applied it negatively.
  false_negative (FN)::
    The number of times a classifier applied a tag negatively whern the human 
    applied it positively.
  true_unknown::
    The number of times a classifier applied ''unknown'' to an item correctly. 
    This is dependant on how a classifier handles unmoderated items.
  unknown:: 
    The number of times a classifier applied ''unknown'' to item when it should 
    have applied a positive or negative tag.
    
These summary statistic are also produced:

  total positives (P)::
    FN + TP
  total negatives (N)::
    TN + FP
  false positive rate::
    FP / N
  true positive rate::
    TP / P
  accuracy::
    (TP + TN)/ (P + N)
  precision::
    TP / (TP + FP)
  recall::
    TP/P

The ranges for determining positive, unknown or negative taggings may be classifier
dependant.  However, for reference, they are currently:

  * negative - (0.0 - 0.3)
  * unknown -  (0.3 - 0.7)
  * positive - (0.7 - 1.0)
    
== Generating a Comparison Report ==

You can easily generate a comparison report by using

{{{
rake cv:report start=<start> end=<end>
}}}

<start> and <end> define the range of cross validation executions to include in the report.
The cross validation run with the lowest id will be used as the baseline for generating comparison
statistics.

    END_HELP
  end
  
  desc "Profile the performance of the cross validation."
  task :profile => ['.seed', :create_results_dir, :environment] do
    require 'ruby-prof'
    ENV['limit'] = '1000'
    folds = (ENV['folds'] or 10)
    seed = (ENV['seed'] or File.read('.seed').to_i)
    cv = CrossValidation.new(:folds => folds, 
                             :seed => seed,
                             :comment => ENV['comment'], 
                             :limit => ENV['limit'],
                             :tags_to_ignore => ['seen', 'duplicate', 'missing entry', RANDOM_BACKGROUND, 'SHORT', /^\*.*/, /^_!not_.*/],
                             :positive_cutoff => ENV['positive_cutoff'],
                             :negative_cutoff => ENV['negative_cutoff'],
                             :classifier_options => parse_classifier_options)

    # Profile the code
    result = RubyProf.profile do
      cv.execute(ENV['result_dir'])
    end

    # Print a graph profile to text
    printer = RubyProf::GraphHtmlPrinter.new(result)
    printer.print(File.open('cv_profile.html', 'w'), 5)
  end
  
  desc "Benchmark the performance of the cross validation."
  task :benchmark => ['.seed', :create_results_dir, :environment] do
    require 'benchmark'
    folds = (ENV['folds'] or 10)
    seed = (ENV['seed'] or File.read('.seed').to_i)
    cv = CrossValidation.new(:folds => folds, 
                             :seed => seed,
                             :comment => ENV['comment'], 
                             :limit => ENV['limit'],
                             :tags_to_ignore => BayesClassifier.non_classified_tags,
                             :positive_cutoff => ENV['positive_cutoff'],
                             :negative_cutoff => ENV['negative_cutoff'],
                             :classifier_options => parse_classifier_options)

    bm = Benchmark.measure do
      cv.execute(ENV['result_dir'])
    end
    
    puts "Benchmark Results:\n"
    puts bm
  end
  
  desc "Execute the cross validation testing."
  task :execute => ['.seed', :create_results_dir, 'tokens:generate'] do
    folds = (ENV['folds'] or 10)
    seed = (ENV['seed'] or File.read('.seed').to_i)
    TOKEN_LOG = File.join(ENV['corpus'], 'tokens.log')
    cv = CrossValidation.new(:corpus => ENV['corpus'],
                             :tagger => ENV['tagger'],
                             :folds => folds, 
                             :seed => seed,
                             :comment => ENV['comment'],
                             :positive_cutoff => ENV['positive_cutoff'],
                             :negative_cutoff => ENV['negative_cutoff'],
                             :classifier_options => parse_classifier_options)
    cv.execute(ENV['result_dir'])          
  end

  desc "Create a report for comparing results between CV runs"
  task :report do
    number_of_results = (ENV['results'] or 10)
    dir = 'cv_results'
    
    if ENV['sub']
      dir = File.join(dir, ENV['sub'])
    end
    
    result_folders = Dir.entries(dir).select do |entry|
      FileTest.directory?(File.join(dir,entry)) and entry != '.' and entry != '..' and entry != '.svn'
    end
    
    result_folders = result_folders.sort_by do |folder|
      File.mtime(File.join(dir, folder))
    end.reverse
    
    result_folders = result_folders.slice(0, number_of_results.to_i).reverse
    
    puts "Generating report for #{result_folders.join", "}."
    
    File.open("cv_results/comparison_table_#{result_folders.join('-')}.html", 'w') do |file|
      file << CrossValidationReport.generate(result_folders, dir)
    end    
  end
  
  desc "Generate a report showing the training count versus the scores."
  task :train_count_report do
    raise "You must specify a result directory relative to cv_results: (result=<result_dir>)" unless ENV['result']
    raise "You must specify a user to print results for: (user=<user>)" unless ENV['user']
    
    dir = File.join('cv_results', ENV['result'])
    TrainCountReport.new(dir, ENV['user']).generate
  end
  
  ## File and folder management tasks
  
  task :reset_seed do
    FileUtils.rm '.seed'
  end
  
  task :create_results_dir => ['cv_results'] do    
    # make a unique(ish) id
    ENV['result_dir'] = "cv_results/" + (rand(117) * 17 * Time.now.to_i.to_f).to_i.to_s(24).upcase
    mkdir ENV['result_dir']
  end
  
  # storing the seed in the file ensures that we get stable subset creation
  rule '.seed' do
    sh "echo #{Time.now.to_i} >> .seed"
  end
  
  directory 'cv_results'
  
  def parse_classifier_options
    options = {}
    options[:bias] = ENV['bias'].to_f if ENV['bias']
    options[:unknown_word_strength] = ENV['uws'].to_f if ENV['uws']
    options[:unknown_word_prob] = ENV['uwp'].to_f if ENV['uwp']
    options[:min_train_count] = ENV['min_train_count'].to_i if ENV['min_train_count']
    options[:min_prob_strength] = ENV['min_prob_strength'].to_f if ENV['min_prob_strength']
    options[:max_discriminators] = ENV['max_discriminators'].to_i if ENV['max_discriminators']
    return options
  end
end
