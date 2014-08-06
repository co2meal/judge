class CreateProblemsTags < ActiveRecord::Migration
  def change
    create_table :problems_tags do |t|
	t.references :problem
	t.references :tag

    end
  end
end
