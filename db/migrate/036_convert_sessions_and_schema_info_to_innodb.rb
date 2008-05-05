class ConvertSessionsAndSchemaInfoToInnodb < ActiveRecord::Migration
  def self.up
    execute "alter table sessions ENGINE=INNODB;"
    execute "alter table schema_info ENGINE=INNODB;"
  end

  def self.down
  end
end
