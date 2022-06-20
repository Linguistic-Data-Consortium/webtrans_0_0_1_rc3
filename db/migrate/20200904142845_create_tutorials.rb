class CreateTutorials < ActiveRecord::Migration[5.2]
    def change
      create_table :tutorials do |t|
        t.string :name
        t.integer :user_id
        t.integer :firststep
        t.integer :nsteps
        t.integer :currentstep
        t.boolean :active
        t.boolean :complete
      end
    end
  end
  