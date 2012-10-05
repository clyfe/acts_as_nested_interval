# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121004204252) do

  create_table "regions", :force => true do |t|
    t.boolean "fiction",                                   :default => false, :null => false
    t.integer "region_id"
    t.integer "lftp",                                                         :null => false
    t.integer "lftq",                                                         :null => false
    t.integer "rgtp",                                                         :null => false
    t.integer "rgtq",                                                         :null => false
    t.decimal "lft",       :precision => 31, :scale => 30,                    :null => false
    t.decimal "rgt",       :precision => 31, :scale => 30,                    :null => false
    t.string  "name",                                                         :null => false
  end

end
