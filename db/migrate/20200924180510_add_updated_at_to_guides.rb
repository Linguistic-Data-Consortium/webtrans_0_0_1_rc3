class AddUpdatedAtToGuides < ActiveRecord::Migration[5.2]
  def change
    add_column :guides, :updated_at, :datetime
  end
end
