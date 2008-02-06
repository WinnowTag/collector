# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Bayes
  # Provides a database based Atom Storage
  class DbAtomStore    
    def initialize(params = {})
      if params and params[:connection]
        @connection = params[:connection]
        @connection_type = :raw
      elsif defined?(ActiveRecord)
        @connection_type = :active_record
      else
        raise ArgumentError, "No connection provided to DbAtomStore"
      end
    end
  
    def read
      atoms = []
      connection = self.connection
      connection.query_with_result = true
      result = connection.query("select id, token from tokens;")
      result.each do |row|
        atoms << [row[0].to_i, row[1]]
      end
      result.free
      atoms
    end
    
    def create_atom(token)
      connection = self.connection      
      connection.query("insert into tokens (`token`) values ('#{Mysql::quote(token)}');")
      connection.insert_id
    end
    
    def connection
      case @connection_type
      when :raw
        @connection
      when :active_record
        ActiveRecord::Base.connection.verify!(300)
        ActiveRecord::Base.connection.connection
      end
    end
  end
end
