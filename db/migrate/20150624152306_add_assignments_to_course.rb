class AddAssignmentsToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :assignments, :hstore
  end
end
