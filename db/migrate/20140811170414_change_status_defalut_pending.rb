class ChangeStatusDefalutPending < ActiveRecord::Migration
  def up
    change_table :submissions do |t|
      t.change :status, :text, default: "Pending"
    end
  end

  def down
    change_table :tablename do |t|
      t.change :status, :text, default: "Pending"
    end
  end
end
