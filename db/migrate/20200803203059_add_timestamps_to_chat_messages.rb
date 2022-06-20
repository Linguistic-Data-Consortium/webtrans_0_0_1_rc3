class AddTimestampsToChatMessages < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :chat_messages, null: false
  end
end
