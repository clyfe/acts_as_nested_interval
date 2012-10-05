class ChangeIntervalPrecision < ActiveRecord::Migration
  def change
    change_column :regions, :lft, :double, null: false
    change_column :regions, :rgt, :double, null: false
  end
end
