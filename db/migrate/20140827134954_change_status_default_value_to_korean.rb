class ChangeStatusDefaultValueToKorean < ActiveRecord::Migration
  def up
    change_column_default :submissions, :status, "대기중"
  end

  def down
    change_column_default :submissions, :status, "Pending"
  end
end
