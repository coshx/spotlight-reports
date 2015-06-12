class AddSchoolAccountToTeachers < ActiveRecord::Migration
  def change
    add_column :teachers, :school_account, :integer
  end
end
