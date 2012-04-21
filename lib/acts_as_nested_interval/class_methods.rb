module ActsAsNestedInterval
  module ClassMethods
    
    # Rebuild the intervals tree
    def rebuild_nested_interval_tree!
      # temporary changes
      skip_callback :update, :before, :update_nested_interval
      old_default_scopes = default_scopes # save to revert later
      default_scope where("#{quoted_table_name}.lftq > 0") # use lft1 > 0 as a "migrated?" flag
          
      # zero all intervals
      update_hash = {lftp: 0, lftq: 0}
      update_hash[:rgtp] = 0 if columns_hash["rgtp"]
      update_hash[:rgtq] = 0 if columns_hash["rgtq"]
      update_hash[:lft]  = 0 if columns_hash["lft"]
      update_hash[:rgt]  = 0 if columns_hash["rgt"]
      update_all update_hash
          
      # recompute intervals with a recursive lambda
      clear_cache!
      update_subtree = ->(node){
        node.create_nested_interval
        node.save
        node.class.unscoped.where(nested_interval_foreign_key => node.id).find_each &update_subtree
      }
      unscoped.roots.find_each &update_subtree

      # revert changes
      set_callback :update, :before, :update_nested_interval
      self.default_scopes = old_default_scopes
    end
    
  end
end