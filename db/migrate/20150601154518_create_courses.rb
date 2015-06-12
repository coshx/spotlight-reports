class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.integer :canvas_id
      t.integer :account_id
      t.string :name

      t.timestamps null: false
    end
  end
end
