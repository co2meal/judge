class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.references :user
      t.references :problem
      t.text :code
      t.text :status

      t.timestamps
    end
  end
end
