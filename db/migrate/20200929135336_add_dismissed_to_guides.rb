class AddDismissedToGuides < ActiveRecord::Migration[6.0]
  def change
    add_column :guides, :dismissed, :boolean
  end
end
  
