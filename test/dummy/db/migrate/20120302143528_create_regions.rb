class CreateRegions < ActiveRecord::Migration
  def change
    create_table :regions do |t|
      t.boolean :fiction, :null => false, :default => false
      t.integer :region_id
      t.integer :lftp, :null => false
      t.integer :lftq, :null => false
      t.integer :rgtp, :null => false
      t.integer :rgtq, :null => false
      t.float :lft, :null => false
      t.float :rgt, :null => false
      t.string :name, :null => false
    end
  end
end
