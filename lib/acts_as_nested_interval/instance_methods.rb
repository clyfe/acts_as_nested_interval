module ActsAsNestedInterval
  module InstanceMethods
    extend ActiveSupport::Concern
    
    # selectively define #descendants according to table features
    included do
      
      if columns_hash["lft"]
        
        def descendants
          quoted_table_name = self.class.quoted_table_name
          nested_interval_scope.where <<-SQL
              #{lftp} < #{quoted_table_name}.lftp AND 
              #{quoted_table_name}.lft BETWEEN #{1.0 * lftp / lftq} AND #{1.0 * rgtp / rgtq}
          SQL
        end
        
      elsif nested_interval_lft_index
        
        def descendants
          quoted_table_name = self.class.quoted_table_name
          nested_interval_scope.where <<-SQL
              #{lftp} < #{quoted_table_name}.lftp AND 
              1.0 * #{quoted_table_name}.lftp / #{quoted_table_name}.lftq BETWEEN 
                #{1.0 * lftp / lftq} AND
                #{1.0 * rgtp / rgtq}
          SQL
        end
        
      elsif connection.adapter_name == "MySQL"
        
        def descendants
          quoted_table_name = self.class.quoted_table_name
          nested_interval_scope.where <<-SQL
              ( #{quoted_table_name}.lftp != #{rgtp} OR 
                #{quoted_table_name}.lftq != #{rgtq}
              ) AND
              #{quoted_table_name}.lftp BETWEEN 
                1 + #{quoted_table_name}.lftq * #{lftp} DIV #{lftq} AND 
                #{quoted_table_name}.lftq * #{rgtp} DIV #{rgtq}
          SQL
        end
        
      else
        
        def descendants
          quoted_table_name = self.class.quoted_table_name
          nested_interval_scope.where <<-SQL
              ( #{quoted_table_name}.lftp != #{rgtp} OR
                #{quoted_table_name}.lftq != #{rgtq}
              ) AND
              #{quoted_table_name}.lftp BETWEEN
                1 + #{quoted_table_name}.lftq * CAST(#{lftp} AS BIGINT) / #{lftq} AND
                #{quoted_table_name}.lftq * CAST(#{rgtp} AS BIGINT) / #{rgtq}
          SQL
        end
        
      end
      
    end
    
    def set_nested_interval(lftp, lftq)
      self.lftp, self.lftq = lftp, lftq
      self.rgtp = rgtp if has_attribute?(:rgtp)
      self.rgtq = rgtq if has_attribute?(:rgtq)
      self.lft = lft if has_attribute?(:lft)
      self.rgt = rgt if has_attribute?(:rgt)
    end
    
    def set_nested_interval_for_top
      if self.class.virtual_root
        set_nested_interval(*next_root_lft)
      else
        set_nested_interval 0, 1
      end
    end

    # Creates record.
    def create_nested_interval
      if read_attribute(nested_interval_foreign_key).nil?
        set_nested_interval_for_top
      else
        set_nested_interval *parent.lock!.next_child_lft
      end
    end

    # Destroys record.
    def destroy_nested_interval
      lock! rescue nil
    end

    def nested_interval_scope
      conditions = {}
      nested_interval_scope_columns.each do |column_name|
        conditions[column_name] = send(column_name)
      end
      self.class.where conditions
    end

    # Updates record, updating descendants if parent association updated,
    # in which case caller should first acquire table lock.
    def update_nested_interval
      changed = send(:"#{nested_interval_foreign_key}_changed?")
      if !changed
        db_self = self.class.find(id, :lock => true)
        write_attribute(nested_interval_foreign_key, db_self.read_attribute(nested_interval_foreign_key))
        set_nested_interval db_self.lftp, db_self.lftq
      else
        # No locking in this case -- caller should have acquired table lock.
        update_nested_interval_move
      end
    end
    
    def update_nested_interval_move
      begin
        db_self = self.class.find(id)
        db_parent = self.class.find(read_attribute(nested_interval_foreign_key))
        if db_self.ancestor_of?(db_parent)
          errors.add nested_interval_foreign_key, "is descendant"
          raise ActiveRecord::RecordInvalid, self
        end
      rescue ActiveRecord::RecordNotFound => e # root
      end
      
      if read_attribute(nested_interval_foreign_key).nil? # root move
        set_nested_interval_for_top
      else # child move
        set_nested_interval *parent.next_child_lft
      end
      mysql_tmp = "@" if ["MySQL", "Mysql2"].include?(connection.adapter_name)
      cpp = db_self.lftq * rgtp - db_self.rgtq * lftp
      cpq = db_self.rgtp * lftp - db_self.lftp * rgtp
      cqp = db_self.lftq * rgtq - db_self.rgtq * lftq
      cqq = db_self.rgtp * lftq - db_self.lftp * rgtq
      
      db_descendants = db_self.descendants
      
      if has_attribute?(:rgtp) && has_attribute?(:rgtq)
        db_descendants.update_all %(
          rgtp = #{cpp} * rgtp + #{cpq} * rgtq,
          rgtq = #{cqp} * #{mysql_tmp}rgtp + #{cqq} * rgtq
        ), mysql_tmp && %(@rgtp := rgtp)
        db_descendants.update_all "rgt = 1.0 * rgtp / rgtq" if has_attribute?(:rgt)
      end
      
      db_descendants.update_all %(
        lftp = #{cpp} * lftp + #{cpq} * lftq,
        lftq = #{cqp} * #{mysql_tmp}lftp + #{cqq} * lftq
      ), mysql_tmp && %(@lftp := lftp)
      
      db_descendants.update_all %(lft = 1.0 * lftp / lftq) if has_attribute?(:lft)
    end
    
    def ancestor_of?(node)
      node.lftp == lftp && node.lftq == lftq ||
        node.lftp > node.lftq * lftp / lftq &&
        node.lftp <= node.lftq * rgtp / rgtq &&
        (node.lftp != rgtp || node.lftq != rgtq)
    end

    def ancestors
      sqls = ['0 = 1']
      p, q = lftp, lftq
      while p != 0
        x = p.inverse(q)
        p, q = (x * p - 1) / q, x
        sqls << "lftq = #{q} AND lftp = #{p}"
      end
      nested_interval_scope.where(sqls * ' OR ')
    end

    # Returns depth by counting ancestors up to 0 / 1.
    def depth
      n = 0
      p, q = lftp, lftq
      while p != 0
        x = p.inverse(q)
        p, q = (x * p - 1) / q, x
        n += 1
      end
      n
    end

    def lft; 1.0 * lftp / lftq end
    def rgt; 1.0 * rgtp / rgtq end

    # Returns numerator of right end of interval.
    def rgtp
      case lftp
      when 0 then 1
      when 1 then 1
      else lftq.inverse(lftp)
      end
    end

    # Returns denominator of right end of interval.
    def rgtq
      case lftp
      when 0 then 1
      when 1 then lftq - 1
      else (lftq.inverse(lftp) * lftq - 1) / lftp
      end
    end

    # Returns left end of interval for next child.
    def next_child_lft
      if child = children.order('lftq DESC').first
        return lftp + child.lftp, lftq + child.lftq
      else
        return lftp + rgtp, lftq + rgtq
      end
    end
    
    # Returns left end of interval for next root.
    def next_root_lft
      vr = self.class.new # a virtual root
      vr.set_nested_interval 0, 1
      if child = nested_interval_scope.roots.order('lftq DESC').first
        return vr.lftp + child.lftp, vr.lftq + child.lftq
      else
        return vr.lftp + vr.rgtp, vr.lftq + vr.rgtq
      end
    end
    
  end
end
