# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#


require File.join(File.dirname(__FILE__), 'file_atom_store')
require File.join(File.dirname(__FILE__), 'db_atom_store')
  
module Bayes # :nodoc:
  # The TokenAtomizer maps a string token used in classification into an Integer.
  #
  # This allows all tokens to be represented internally as Integers to improve
  # performance and memory usage.  There are two class level methods on Token
  # that can be used to convert between global and local versions.
  #
  # == Getting an Instance
  #
  # You should always call TokenAtomizer.get_atomizer to get an instance of the atomizer.
  # This will ensure that you either get a local singleton instance or a singleton remote
  # object.
  #
  # == Token Log
  #
  # Existing mappings are stored in a tokens.log file in RAILS_ROOT/log. The log file format
  # is an atom and corresponding token on each line, separated by a comma.
  #
  class TokenAtomizer
    SUPPORTED_STORES = [:file, :db]
    JOB_KEY= 'token_atomizer' unless defined?(JOB_KEY)
    @@atomizer = nil
    # Sets the default TokeAtomizer.store to :File    
    @store = :file
    
    class << self
      attr_reader :store
      attr_accessor :store_params
      
      def store=(new_store)        
        unless SUPPORTED_STORES.include?(new_store)
          raise ArgumentError, "TokenAtomizer.store must be one of #{SUPPORTED_STORES.join(" or ")}."
        end
        
        @store = new_store
      end
        
      # Gets an instance of the TokenAtomizer.
      #
      # This will first check to see if there is a BackgroundRB server running will the settings
      # defined in RAILS_ROOT/config/backgroundrb.yml, if there is a TokenAtomizerWorker running
      # in that BackgroundRB server is returned, otherwise a local singleton instance is returned.
      #
      # When the tokens.log file is large, there can be a bit of overhead in creating a TokenAtomizer,
      # which is why using a BackgroundRB worker is preferable since the log file only needs to be read
      # once for many processes.
      #
      def get_atomizer
        begin
          MiddleMan.new_worker(:class => :token_atomizer_worker, 
                               :job_key => JOB_KEY, 
                               :args => {:store => self.store})
          MiddleMan[JOB_KEY].object
        rescue
          unless @@atomizer 
            @@atomizer = self.new
          end
          @@atomizer
        end
      end
    end
  
    attr_accessor :store
  
    # Setup the token maps by reading in the tokens.log file.
    #
    def initialize(store_type = TokenAtomizer.store, store_params = TokenAtomizer.store_params) # :notnew:
      case store_type
      when :file then self.store = FileAtomStore.new(store_params)
      when :db   then self.store = DbAtomStore.new(store_params)
      else
        raise ArgumentError, "Unknown store_type: #{store_type}"
      end
          
      @atom_to_token_map = {}
      @token_to_atom_map = {}
      store.read.each do |atom, token|
        @atom_to_token_map[atom] = token
        @token_to_atom_map[token] = atom
      end  
    end
  
    # For testing purposes only
    def set_token_pools(atom_to_token_map, token_to_atom_map) # :nodoc:
      @max_id = atom_to_token_map.keys.max
      @atom_to_token_map = atom_to_token_map
      @token_to_atom_map = token_to_atom_map
    end
  
    # For testing purposes only
    def token_pools # :nodoc:
      [@atom_to_token_map, @token_to_atom_map]
    end
  
    # Localize tokens in a object.
    #
    # Localize takes token strings and converts them to integer ids which can be used internally for speed
    # and lower memory consumption.
    #
    # This method takes String, Array of String or a Hash with String keys.
    #
    # <tt>String</tt>:: The String is converted to an Integer according to the token mapping.
    # <tt>Array</tt>:: All the String elements of the array are convert to integers according to the token mapping.
    # <tt>Hash</tt>:: All the String keys of the hash are converted to integers, the values of the hash are untouched.
    #
    # If the string provided doesn't exist in the mapping a new mapping entry will be created for it and it
    # will be assigned an id.  The new entry will be added to the +new_tokens+ array of the +token_pool+ which
    # will need to be +flushed+ in order to save the entry to the database.
    #
    # This method will raise an ArgumentError an object other than an Integer, Array or Hash is provided.
    #
    def localize(o)
      case o
        when String then id_for(o)
        when Array  then o.map {|e| id_for(e)}
        when Hash   then o.inject({}) {|h, (key, value)| h[id_for(key)] = value; h}
        else
          raise ArgumentError, "Dont know how to localize a #{o.class}, only [String, Array or Hash]"
      end
    end
  
    # Globalizes tokens in a object.
    #
    # Globalizing takes token ids and converts them to tokens which are
    # then portable between systems.
    #
    # This method takes an Integer, Array of Integers or a Hash with Integer keys.
    #
    # <tt>Integer</tt>:: The Integer is converted to string according to the token mapping.
    # <tt>Array</tt>:: All the Integer elements of the array are convert to strings according to the token mapping.
    # <tt>Hash</tt>:: All the Integer keys of the hash are converted to strings, the values of the hash are untouched.
    #
    # This method will raise an ArgumentError if an Integer to be mapped does not exist in the token mapping or
    # an object other than an Integer, Array or Hash is provided.
    #
    def globalize(o)
      case o
        when Integer then token_for(o)
        when Array   then o.map {|i| globalize(i) }
        when Hash    then o.inject({}) {|h, (key, value)| h[token_for(key)] = value; h}
        else
          o
      end
    end
     
    def to_s
      "<Bayes::TokenAtomizer token_count = #{@atom_to_token_map.size}>"
    end
    
    def inspect; to_s; end
    
    
    private
    # Gets the token for a given id
    #
    # <tt>i</tt>:: The id of the token to retrieve.
    #
    # Raises an ArgumentError if there is no token matching that id.
    #
    def token_for(atom) # :doc:
      unless token = @atom_to_token_map[atom]
        raise ArgumentError, "No token with id = #{atom}."
      end
  
      token
    end

    # Gets the id for a given token
    #
    # <tt>s</tt>:: The token to get the id for.
    #
    # If the token doesn't currently have an id mapped to it
    # a new Token AR object is created and assigned an id.
    # The new id and the token are the written to the tokens.log file.
    #
    def id_for(token) # :doc:
      unless atom = @token_to_atom_map[token]
        atom = store.create_atom(token)
        @token_to_atom_map[token] = atom
        @atom_to_token_map[atom] = token
      end
    
      atom
    end
  end
end