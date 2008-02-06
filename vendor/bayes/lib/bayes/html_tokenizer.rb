# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'hpricot'
require 'bayes/token_atomizer'


module Bayes # :nodoc
  # = Feed Item Tokenizer
  #
  # Initially our tokenization improvements were done under the philosophy of
  # only adding a change if there was a marked improvement in the classification
  # results. However this was modified to aim for cleaner tokens as long as there
  # was no drop in classification performance, for example, a change that removed punctuation
  # from tokens that didn't have an adverse effect on classification would be kept in the tokenizer.
  #
  # We may want to revisit this when we have more corpora for cross validation.
  #
  # == Tokenizer Improvement History
  #
  # === Initial tokenizer
  #
  # The tokenizer was initially Regex based, it would strip HTML tags
  # by removing any characters between two angle-brackets then split 
  # the resulting string on white space.  This had the problem that
  # the following piece of HTML:
  #
  #   foo.<br/>Bar
  #
  # would result in a single token: foo.Bar
  #
  # The regex tokenizer also meant doing more complicated tokenization
  # involves increasingly complicated Regexes.
  #
  # Ruby has available to it a very fast and clever HTML parser that can correct
  # alot of poorly formatted HTML and provide a HTML syntax tree which you can then
  # traverse. So I wanted to try that out in place of the Regex parser.
  #
  # === Trying Hpricot
  #
  # The initial version of the Hpricot based tokenizer performed worse than the 
  # regex based tokenizer.  This prompted me to add token dumping to the cross
  # validation code so we could inspect the difference.  By inspecting the tokens
  # produced by each tokenizer I noticed that the Hpricot based tokenizer was 
  # missing alot of tokens that were produced by the regex based tokenizer.  
  # After a bit of investigation I noticed that the Hpricot tokenizer was missing
  # all the top level text in a piece of content. This was caused by the fact that
  # I was using the traverse_all_element method, I then discovered the 
  # traverse_all_text method and the problem was solved.
  #
  # This fixed version of the hpricot tokenizer then performed better than the 
  # original regex based tokenizer.  Further inspection of the tokens revealed 
  # the problem described above where the regex based parser was joining tokens 
  # that had HTML between them.
  #
  # So from this point we decided to proceed with the Hpricot tokenizer as the 
  # base since it gave slight improvements in results and provides a more flexible
  # base on which to add additional processing.
  #
  # === Case Folding
  #
  # Case folding seemed to produce no real benefit to classification performance.  The dictionary size was only reduced by 
  # about 10%, true negatives got about a 0.22% boost and true positives dropped about 1.0%.
  #
  # === Punctuation Stripping 
  # 
  # I tried a number of different methods for stripping out punctuation:
  #
  # * Replace all characters except alpha numerics and dashes with a space
  # * Replace all characters except alpha numerics and dashes with an empty string.
  # * Replace all characters except alpha numerics and non-leading dashes with an empty string.
  # * Strip HTML entities then strip all characters except alpha numerics and non-leading dashes with an empty string.
  #
  # Replacing with an empty string performed slightly better as did striping non-leading dashes, 
  # but in all cases stripping away punctuation gave worse results than leaving it in. So this led me to 
  # think that punctuation is helping some token 'hits', but intuitively it is also causing some token 'misses'
  # I thought I would try stripping punctuation on a token by token basis and adding both the raw token
  # and the stripped token and see what would happen.
  #
  # This was an improvement over the other punctuation stripping in overall true positives and slightly 
  # ahead of the baseline in true positives for normal tags but the baseline beats in for unwanteds. It 
  # was about a 1% improvement in true negatives for unwanteds but a 1.5 percent drop in true negatives 
  # for the normals.
  #
  # While the scores weren't that convincing, the tokens were significantly cleaner so the changes went in.
  #
  # === Stop words
  #
  # SpamBayes would ignore words with less than 3 characters.  This will catch alot of words
  # that would normally be considered stop words in the English language. So I first tried this.
  #
  # Secondly I tried removing this list of stop words from the resulting tokens:
  #
  #  a an and are as at be but by for
  #  from had have her his in is it not of
  #  on or that the this to was which with you
  #
  # Neither feature produced gains signficant enough to be included in the tokenizer
  #
  # === Tokenizing URLs
  #
  # All the previous tokenization methods would ignore URLs that appeared in attributes of 
  # HTML elements, such as 'href' attributes of 'a' elements and 'src' attributes of 'link'
  # elements. So we tried a scheme that would extract any URL from 'href' or 'src' attributes
  # of any element and break the URL up into scheme, hostname, path and fragment.  These were
  # each added as tokens prefixed by 'URLSeg'.
  #
  # Testing proved that this was a worthwhile change with 4.3% increase in overall true postives and
  # 0.9% increase in overall true negatives.
  #
  # At some point we will probably want to revisit tokenization of URL paths since they produce lots of unique
  # tokens that likely don't add any value to the classification.
  # 
  # === Tokenizing HTML
  #
  # All previous tokenization would completely throw away HTML tags. We then tried a scheme where
  # HTML tags were added as tokens prefixed by HTMLTag.  By itself this was a loser since it had
  # 0.4% increases in TPs for unwanteds but a 1% decrease in TPs for normals.  TNs went up 0.5%
  # for normals but down 0.5% for unwanteds.
  #
  # When combined with URL tokenization the results were similar when compared to URL tokenization alone.
  # Since the results for HTML tokenization were less clearly positive, HTML tokenization has been left out
  #
  # 
  class HtmlTokenizer   
    attr_accessor :atomize_tokens
    def initialize(atomize_tokens = true)
      @atomize_tokens = atomize_tokens
    end 
  
    # Gets the tokens for some HTML content.
    #
    # If the tokens don't exist already they are created.
    #
    def tokens(content)
      tokens_with_counts(content).keys
    end
  
    # Gets the tokens and token counts for some HTML content.
    #
    # If the tokens don't exist they are created.
    #
    def tokens_with_counts(content)
      tokenize(content)
    end
  
    protected
    # Performs the actual tokenization of HTML content
    #
    def tokenize(content)
      doc = Hpricot(content)
    
      # do the raw text, first collect it all into a string
      text = ""
    
      doc.traverse_text do |text_node|
        text += (text_node.content + ' ')
      end
            
      text = text.downcase                           # Fold The case
      text = text.gsub(/&[^;]+;/, ' ')               # Remove HTML Entities
      text = text.gsub(/[^a-zA-Z0-9\-]/, ' ')        # Remove all non-alphanumerics except dashes
      text = text.gsub(/\s+\-+/, ' ')                # Remove leading and trailing dashes
      text = text.gsub(/\-+\s+/, ' ')
      tokens = text.split.select{|tok| tok.size > 1} # Split on whitespace and remove single character tokens
            
      # Tokenize all URLs in the content and the URL to the actual item        
      uris = []        
    
      doc.search('[@href]').each do |e|
        uris << e['href']
      end
    
      doc.search('[@src]').each do |e|
        uris << e['src']
      end
    
      uris.compact.each do |uri|
        tokens += tokenize_uri(uri)
      end
    
      # Convert the array of tokens into a hash of token => frequency pairs
      tokens = tokens.inject(Hash.new(0)) do |h, token|
        h[token] += 1
        h
      end
    
      @atomize_tokens ? TokenAtomizer.get_atomizer.localize(tokens) : tokens
    end  
  
    def tokenize_uri(uri)
      begin
        tokens = []
        uri = URI.parse(uri)
      
        if uri.scheme == 'http'
          # Strip www from the front so www.foo.com matches foo.com
          host = uri.host.sub(/^www\./, '')
          unless host.nil? or host.empty? or not host.size > 3
            tokens << "URLSeg:#{host}" 
          end
        
          unless uri.path.nil? or uri.path.empty? or not uri.path.size > 3
            tokens << "URLSeg:#{uri.path}" 
          end
        elsif uri.scheme == nil
          tokens << "URLSeg:#{uri.path}" unless uri.path.nil? or uri.path.empty? or not uri.path.size > 3
        end
      
        tokens
      rescue
        []
      end
    end
  end
end
