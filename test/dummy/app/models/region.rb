class Region < ActiveRecord::Base
  acts_as_nested_interval :foreign_key => :region_id, :scope_columns => :fiction
end
