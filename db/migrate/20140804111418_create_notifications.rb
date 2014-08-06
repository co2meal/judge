class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
    	t.string :subject
    	t.text :body

    	t.references :user, index: true
      t.timestamps
    end
  end
end
