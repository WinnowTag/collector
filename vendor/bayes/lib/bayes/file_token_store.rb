# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Bayes
  class FileTokenStore
    ATOMIZED_FLAG = 'A'[0]
    NON_ATOMIZED_FLAG = 'N'[0]
    ATOMIZED_TEMPLATE = "ii"
    NON_ATOMIZED_TEMPLATE = "ui"
    
    attr_accessor :token_directory
    def initialize
      @token_directory = "tokens"
      yield(self) if block_given?
    end
    
    def store(taggable_id, tokens, options = {})      
      File.open(File.join(@token_directory, "#{taggable_id}.tokens"), 'w') do |f|
        if options[:atomized] or infer_atomized(tokens)
          atomized_flag = ATOMIZED_FLAG
          packing_template = ATOMIZED_TEMPLATE
        else
          atomized_flag = NON_ATOMIZED_FLAG
          packing_template = NON_ATOMIZED_TEMPLATE
        end
        
        data = [atomized_flag, tokens.size] + tokens.to_a.flatten
        f << data.to_a.flatten.pack("ci" + (packing_template * tokens.size))
      end
    end
    
    def read(taggable_id)
      token_file = File.join(@token_directory, "#{taggable_id}.tokens")
      if File.exists?(token_file)
        File.open(token_file, 'r') do |f|
          atomized_flag = f.readchar
          size = f.read(4).unpack("i").first
          
          if atomized_flag == ATOMIZED_FLAG
            template = ATOMIZED_TEMPLATE
          elsif atomized_flag == NON_ATOMIZED_FLAG
            template = NON_ATOMIZED_TEMPLATE
          else
            raise IOError, "Unknown token file format"
          end
          
          Hash[*f.read.unpack(template * size)]
        end
      end
    end
    
    private
    def infer_atomized(tokens)
      tokens.all? {|k, v| k.is_a?(Numeric)}
    end        
  end
end