class AddStatusToProjectUser < ActiveRecord::Migration[6.0]
  def change
    add_column :project_users, :status, :string
  end
end
