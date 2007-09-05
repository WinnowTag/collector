class CreateProtectedItems < ActiveRecord::Migration
  def self.up
    create_table :protected_items do |t|
      t.column :feed_item_id, :integer
      t.column :protector_id, :integer
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
  end

  def self.down
    drop_table :protected_items
  end
end
