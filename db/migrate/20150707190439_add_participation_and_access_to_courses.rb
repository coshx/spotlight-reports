class AddParticipationAndAccessToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :participation_and_access, :hstore
  end
end
