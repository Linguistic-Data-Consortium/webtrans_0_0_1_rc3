class CreateScript < ActiveRecord::Migration[6.0]
  def change
    create_table :scripts do |t|
      t.string :name
      t.integer :user_id
      t.text :description
      t.text :code
    end
    add_index :scripts, [ :user_id, :name ], :unique => true
  end
end
