class ChangeIntervalPrecision < ActiveRecord::Migration
  def change
    change_column :regions, :lft, :decimal, precision: 31, scale: 30, null: false
    change_column :regions, :rgt, :decimal, precision: 31, scale: 30, null: false
  end
end
