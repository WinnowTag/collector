# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Bayes
  # Provides a file based Atom Storage
  class FileAtomStore
    def initialize(params = {})
      @max_id = 0
    
      if params && params[:token_log]
        @token_log = token_log
      elsif defined?(RAILS_ENV)
        if RAILS_ENV == "test"
          @token_log = File.join(RAILS_ROOT, 'log', 'tokens.log.test')
        else
          @token_log = File.join(RAILS_ROOT, 'log', 'tokens.log')
        end
      elsif defined?(TOKEN_LOG)
        @token_log = TOKEN_LOG
      else
        @token_log = 'tokens.log'
      end
    end
  
    def read
      atoms = []
      if File.exists?(@token_log)
        File.open(@token_log, 'r') do |f|
          f.each_line do |line|
            if line =~ /^(\d+),(.*)$/
              atoms << [$1.to_i, $2]
              @max_id = [@max_id, $1.to_i].max
            else
              logger.warn("Badly formatted token line: #{line}")
            end
          end
        end
      end
    
      return atoms
    end
  
    def create_atom(token)
      atom = (@max_id += 1)
      File.open(@token_log, 'a') do |f|
        f.write("#{atom},#{token}\n")
      end
      
      atom
    end
  end
end
