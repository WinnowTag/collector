class IndexSpiderResultsCreatedAt < ActiveRecord::Migration
  def self.up
    add_index(:spider_results, :created_at)
  end

  def self.down
  end
end
