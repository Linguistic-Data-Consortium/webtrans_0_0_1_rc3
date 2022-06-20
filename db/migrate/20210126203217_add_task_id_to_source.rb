class AddTaskIdToSource < ActiveRecord::Migration[6.0]
  def change
    add_column :sources, :task_id, :integer
  end
end
