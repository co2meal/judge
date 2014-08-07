class CreateSystemTests < ActiveRecord::Migration
  def change
    create_table :system_tests do |t|
      t.text :input_data
      t.references :problem, index: true

      t.timestamps
    end
  end
end
