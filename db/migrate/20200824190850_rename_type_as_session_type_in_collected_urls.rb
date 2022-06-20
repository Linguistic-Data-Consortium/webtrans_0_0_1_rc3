class RenameTypeAsSessionTypeInCollectedUrls < ActiveRecord::Migration[5.2]
  def change
    rename_column :collected_urls, :type, :session_type
  end
end
