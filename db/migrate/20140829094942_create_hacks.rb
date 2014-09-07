# coding: utf-8

class CreateHacks < ActiveRecord::Migration
  def change
    create_table :hacks do |t|
      t.references :user, index: true
      t.references :submission, index: true
      t.text :input_data
      t.string :status, default: "대기중"

      t.timestamps
    end
  end
end
