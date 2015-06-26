class AddGradesToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :grades, :hstore
  end
end
