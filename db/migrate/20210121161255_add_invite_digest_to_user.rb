class AddInviteDigestToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :invite_digest, :string
    add_column :users, :invite_sent_at, :datetime
    add_column :users, :invite_sent_by, :integer
  end
end
