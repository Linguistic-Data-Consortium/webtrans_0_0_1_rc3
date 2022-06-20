class AddMetaToKitType < ActiveRecord::Migration[5.2]
  def change
    add_column :kit_types, :meta, :text
  end
end
