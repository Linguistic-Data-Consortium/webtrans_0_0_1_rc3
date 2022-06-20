class AddOrigIdToKit < ActiveRecord::Migration[6.0]
  def change
    add_column :kits, :orig_id, :integer
  end
end
