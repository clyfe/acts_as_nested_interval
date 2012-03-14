# ActsAsNestedInterval

## About

Pythonic's acts_as_nested_interval updated to Rails 3 and gemified.

This act implements a nested-interval tree. You can find all descendants or all
ancestors with just one select query. You can insert and delete records without
a full table update (compared to nested set, where at insert, half the table is updated on average).

Nested sets/intervals are good if you need to sort in preorder at DB-level.
If you don't need that give a look to https://github.com/stefankroes/ancestry ,
that implements a simpler encoding model (variant of materialized path).


## Install

```ruby
# add to Gemfile
gem 'acts_as_nested_interval'
```

```sh
# install
bundle install
```

* requires a `parent_id` foreign key column, and `lftp` and `lftq` integer columns.
* if your database does not support stored procedures then you also need `rgtp` and `rgtq` integer columns
* if your database does not support functional indexes then you also need a `rgt` float column
* the `lft` float column is optional

Example:

```ruby
create_table :regions do |t|
  t.integer :parent_id
  t.integer :lftp, :null => false
  t.integer :lftq, :null => false
  t.integer :rgtp, :null => false
  t.integer :rgtq, :null => false
  t.float :lft, :null => false
  t.float :rgt, :null => false
  t.string :name, :null => false
end
add_index :regions, :parent_id
add_index :regions, :lftp
add_index :regions, :lftq
add_index :regions, :lft
add_index :regions, :rgt
```

## Usage

The size of the tree is limited by the precision of the integer and floating
point data types in the database.

This act provides these named scopes:

```ruby
Region.roots    # returns roots of tree.
Region.preorder # returns records for preorder traversal.
```

This act provides these instance methods:

```ruby
Region.parent      # returns parent of record.
Region.children    # returns children of record.
Region.ancestors   # returns scoped ancestors of record.
Region.descendants # returns scoped descendants of record.
Region.depth       # returns depth of record.
```

Example:

```ruby
class Region < ActiveRecord::Base
  acts_as_nested_interval
end

earth = Region.create :name => "Earth"
oceania = Region.create :name => "Oceania", :parent => earth
australia = Region.create :name => "Australia", :parent => oceania
new_zealand = Region.new :name => "New Zealand"
oceania.children << new_zealand
earth.descendants      # => [oceania, australia, new_zealand]
earth.children         # => [oceania]
oceania.children       # => [australia, new_zealand]
oceania.depth          # => 1
australia.parent       # => oceania
new_zealand.ancestors  # => [earth, oceania]
Region.roots           # => [earth]
```

## How it works

The **mediant** of two rationals is the rational with the sum of the two
numerators for the numerator, and the sum of the two denominators for the
denominator (where the denominators are positive).  
The mediant is numerically between the two rationals.  
Example: `3/5` is the mediant of `1/2` and `2/3`, and `1/2 < 3/5 < 2/3`.  

Each record "covers" a half-open interval `(lftp/lftq, rgtp/rgtq]`.  
The tree root covers `(0/1, 1/1]`.  
The first child of a record covers interval `(mediant{lftp/lftq, rgtp/rgtq}, rgtp/rgtq]`.  
The next child covers the interval
 `(mediant{lftp/lftq, mediant{lftp/lftq, rgtp/rgtq}}, mediant{lftp/lftq, rgtp/rgtq}]`.  

With this construction each lftp and lftq are relatively prime and the identity
`lftq * rgtp = 1 + lftp * rgtq` holds.

Example:

                 0/1                           1/2   3/5 2/3                 1/1
    earth         (-----------------------------------------------------------]
    oceania                                     (-----------------------------]
    australia                                             (-------------------]
    new zealand                                       (---]

The descendants of a record are those records that cover subintervals of the
interval covered by the record, and the ancestors are those records that cover
superintervals.

Only the left end of an interval needs to be stored, since the right end can be
calculated (with special exceptions) using the above identity:

    rgtp := x
    rgtq := (x * lftq - 1) / lftp

where x is the inverse of lftq modulo lftp.

Similarly, the left end of the interval covered by the parent of a record can
be calculated using the above identity:

    lftp := (x * lftp - 1) / lftq
    lftq := x

where x is the inverse of lftp modulo lftq.

## Moving nodes

To move a record from `old.lftp, old.lftq` to `new.lftp, new.lftq`, apply this
linear transform to lftp, lftq of all descendants:

    lftp := (old.lftq * new.rgtp - old.rgtq * new.lftp) * lftp
             + (old.rgtp * new.lftp - old.lftp * new.rgtp) * lftq
    lftq := (old.lftq * new.rgtq - old.rgtq * new.lftq) * lftp
             + (old.rgtp * new.lftq - old.lftp * new.rgtq) * lftq

You should acquire a table lock before moving a record.

Example:

```ruby
pacific = Region.create :name => "Pacific", :parent => earth
oceania.parent = pacific
oceania.save!
```

## Migrating from acts_as_tree

If you come from acts_as_tree or another system where you only have a parent_id,
to rebuild the intervals based on `acts_as_nested_set`, after you migrated the DB
and created the columns required by `acts_as_nested_set` run:

```ruby
Region.rebuild_nested_interval_tree!
```

NOTE! About `rebuild_nested_interval_tree!`:  
It zeroes all your tree intervals before recomputing them!  
It does a lot of N+1 queries of type `record.parent` and not only.
This might change once the AR identity_map is finished.

## Authors

This: https://github.com/clyfe/acts_as_nested_interval  
Original: https://github.com/pythonic/acts_as_nested_interval  
Acknowledgement: http://arxiv.org/html/cs.DB/0401014 by Vadim Tropashko.  