class AddcolumnTo < ActiveRecord::Migration
  def change
  	add_column :problems, :check_code, :text
  	add_column :problems, :judge_code, :text
  end
end
