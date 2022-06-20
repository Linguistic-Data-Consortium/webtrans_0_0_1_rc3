class AppearanceChannel < ApplicationCable::Channel

    # called when a user subscribes to the appearance channel
    def subscribed

      # add current user to cache, set key to expire in 15 minutes
      $active_users.set(current_user, "")
      $active_users.expire(current_user, 900)

      ActionCable.server.broadcast "appearance_channel", message: "user connected!"
      stream_from 'appearance_channel'
    end

    # called when subscription is terminated
    def unsubscribed

      # remove current user key from cache (flag as offline)
      $active_users.del(current_user)

      ActionCable.server.broadcast "appearance_channel", message: "user disconnected!", user: current_user
      stream_from 'appearance_channel'
    end

end
