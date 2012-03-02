# ActsAsNestedInterval

Pythonic's acts_as_nested_interval updated to Rails 3 and gemified.
This: https://github.com/clyfe/acts_as_nested_interval
Original: https://github.com/pythonic/acts_as_nested_interval
Acknowledgement: http://arxiv.org/html/cs.DB/0401014 by Vadim Tropashko.

This act implements a nested-interval tree. You can find all descendants or all
ancestors with just one select query. You can insert and delete records without
a full table update.

This act requires a "parent_id" foreign key column, and "lftp" and "lftq"
integer columns. If your database does not support stored procedures then you
also need "rgtp" and "rgtq" integer columns, and if your database does not
support functional indexes then you also need a "rgt" float column. The "lft"
float column is optional.

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
create_index :regions, :parent_id
create_index :regions, :lftp
create_index :regions, :lftq
create_index :regions, :lft
create_index :regions, :rgt
```

The size of the tree is limited by the precision of the integer and floating
point data types in the database.

This act provides these named scopes:
  roots -- returns roots of tree.
  preorder -- returns records for preorder traversal.

This act provides these instance methods:
  parent -- returns parent of record.
  children -- returns children of record.
  ancestors -- returns scoped ancestors of record.
  descendants -- returns scoped descendants of record.
  depth -- returns depth of record.

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
earth.descendants
# => [oceania, australia, new_zealand]
earth.children
# => [oceania]
oceania.children
# => [australia, new_zealand]
oceania.depth
# => 1
australia.parent
# => oceania
new_zealand.ancestors
# => [earth, oceania]
Region.roots
# => [earth]
```

The "mediant" of two rationals is the rational with the sum of the two
numerators for the numerator, and the sum of the two denominators for the
denominator (where the denominators are positive). The mediant is numerically
between the two rationals. Example: 3 / 5 is the mediant of 1 / 2 and 2 / 3,
and 1 / 2 < 3 / 5 < 2 / 3.

Each record "covers" a half-open interval (lftp / lftq, rgtp / rgtq]. The tree
root covers (0 / 1, 1 / 1]. The first child of a record covers interval
(mediant{lftp / lftq, rgtp / rgtq}, rgtp / rgtq]; the next child covers
interval (mediant{lftp / lftq, mediant{lftp / lftq, rgtp / rgtq}},
                   mediant{lftp / lftq, rgtp / rgtq}].

With this construction each lftp and lftq are relatively prime and the identity
lftq * rgtp = 1 + lftp * rgtq holds.

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

To move a record from old.lftp, old.lftq to new.lftp, new.lftq, apply this
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
