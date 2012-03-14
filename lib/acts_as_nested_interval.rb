# Copyright (c) 2007, 2008 Pythonic Pty Ltd
# http://www.pythonic.com.au/

# Copyright (c) 2012 Nicolae Claudius
# https://github.com/clyfe

require 'acts_as_nested_interval/core_ext/integer'
require 'acts_as_nested_interval/version'
require 'acts_as_nested_interval/instance_methods'
require 'acts_as_nested_interval/class_methods'

# This act implements a nested-interval tree. You can find all descendants
# or all ancestors with just one select query. You can insert and delete
# records without a full table update.
module ActsAsNestedInterval
  
  # The +options+ hash can include:
  # * <tt>:foreign_key</tt> -- the self-reference foreign key column name (default :parent_id).
  # * <tt>:scope_columns</tt> -- an array of columns to scope independent trees.
  # * <tt>:lft_index</tt> -- whether to use functional index for lft (default false).
  # * <tt>:virtual_root</tt> -- whether to compute root's interval as in an upper root (default false)
  def acts_as_nested_interval(options = {})
    cattr_accessor :nested_interval_foreign_key
    cattr_accessor :nested_interval_scope_columns
    cattr_accessor :nested_interval_lft_index
      
    cattr_accessor :virtual_root
    self.virtual_root = !!options[:virtual_root]
      
    self.nested_interval_foreign_key = options[:foreign_key] || :parent_id
    self.nested_interval_scope_columns = Array(options[:scope_columns])
    self.nested_interval_lft_index = options[:lft_index]
      
    belongs_to :parent, class_name: name, foreign_key: nested_interval_foreign_key
    has_many :children, class_name: name, foreign_key: nested_interval_foreign_key, dependent: :destroy
    scope :roots, where(nested_interval_foreign_key => nil)
      
    if columns_hash["rgt"]
      scope :preorder, order('rgt DESC, lftp ASC')
    elsif columns_hash["rgtp"] && columns_hash["rgtq"]
      scope :preorder, order('1.0 * rgtp / rgtq DESC, lftp ASC')
    else
      scope :preorder, order('nested_interval_rgt(lftp, lftq) DESC, lftp ASC')
    end

    before_create :create_nested_interval
    before_destroy :destroy_nested_interval
    before_update :update_nested_interval
      
    include ActsAsNestedInterval::InstanceMethods
    extend ActsAsNestedInterval::ClassMethods
  end

end

ActiveRecord::Base.send :extend, ActsAsNestedInterval
