class AddMiscToGuides < ActiveRecord::Migration[6.0]
  def change
    add_column :guides, :misc, :string
  end
end
