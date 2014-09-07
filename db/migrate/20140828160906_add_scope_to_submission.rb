class AddScopeToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :scope, :string, default: 'private'
  end
end
