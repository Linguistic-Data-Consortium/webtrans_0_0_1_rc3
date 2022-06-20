class CreateFeature < ActiveRecord::Migration[6.0]
  def change
    create_table :features do |t|
      t.string :category
      t.string :name
      t.string :value
      t.string :label
      t.text :description
      t.timestamps
    end
    add_index :features, [ :category, :name ], :unique => true
  end
end
