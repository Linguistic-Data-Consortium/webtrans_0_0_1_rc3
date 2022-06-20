class AppearanceController < ApplicationController
  before_action :authenticate_or_die

  # resets current user's TTL in Redis to 15 minutes
  def refresh
    $active_users.expire(current_user.name, 900)

    # debug statement, outputs each active user's TTL
    # $active_users.keys.each {|k| puts(k); puts($active_users.ttl(k)) }
    # puts('reset TTL for ' + current_user.name)
    
    render json: {name: current_user.name}
  end

end
