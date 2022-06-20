class AddCommentAndCenterToCollectedUrls < ActiveRecord::Migration[5.2]
  def change
    add_column :collected_urls, :comment, :text
    add_column :collected_urls, :center, :string
  end
end
