class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers do |t|
      t.integer :canvas_id
      t.string :name
      t.string :sortable_name
      t.string :email
      t.string :avatar_url
      t.datetime :last_login

      t.timestamps null: false
    end
  end
end
