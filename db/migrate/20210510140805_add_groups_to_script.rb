class AddGroupsToScript < ActiveRecord::Migration[6.0]
  def change
    add_column :scripts, :rgroup_id, :integer
    add_column :scripts, :wgroup_id, :integer
    add_column :scripts, :xgroup_id, :integer
  end
end
