class AddGradesByAssignmentToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :grades_by_assignment, :hstore
  end
end
