namespace :tokens do
  desc "Generates tokens for a corpus"
  task :generate do
    require "cv/taggable"
    require "cv/taggable_tokenizer"
    require "progressbar"
    
    corpus = get_corpus
    
    cd(corpus) do
      tokenizer = TaggableTokenizer.new(corpus)
      taggables = Taggable.find(corpus)
      progress_bar = ProgressBar.new("Tokenizing", taggables.size)
    
      taggables.each do |taggable|
        tokenizer.tokens_with_counts(taggable)
        progress_bar.inc
      end
    
      progress_bar.finish
    end
  end
  
  desc "Remove existing tokens"
  task :clean do
    corpus = get_corpus
    cd(corpus) do
      puts "rm -f *.tokens"
      rm Dir.glob("*.tokens"), :verbose => false, :force => true
      rm "tokens.log", :force => true
    end
  end
  
  desc "Remove existing tokens and regenerate"
  task :regenerate => [:clean, :generate]
  
  def get_corpus
    corpus = ENV['corpus']
    if corpus.nil?
      raise "You must provide a corpus directory"
    elsif !File.exists?(corpus)
      raise "Corpus directory: #{corpus} does not exist"
    else
      return corpus
    end
  end
end