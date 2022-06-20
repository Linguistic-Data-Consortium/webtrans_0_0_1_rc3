class AddTypeToCollectedUrls < ActiveRecord::Migration[5.2]
  def change
    add_column :collected_urls, :type, :string
  end
end
  