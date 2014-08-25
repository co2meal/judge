class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.text :content
      t.references :problem, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end
