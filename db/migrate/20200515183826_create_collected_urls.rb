class CreateCollectedUrls < ActiveRecord::Migration[5.2]
  def change
    create_table :collected_urls do |t|
      t.string :url
      t.string :coordinator
      t.string :inddid
      t.datetime :when
      t.integer :user_id
      t.string :tag

      t.timestamps
    end
  end
end
