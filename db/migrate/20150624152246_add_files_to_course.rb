class AddFilesToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :files, :hstore
  end
end
