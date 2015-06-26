class AddDiscussionsToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :discussions, :hstore
  end
end
