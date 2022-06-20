class ChatController < ApplicationController

  def show
    @messages = ChatMessage.all
    render 'index'
  end

  def create

    user = User.find_by_id(cookies.encrypted['_ua_session']['user_id']).name
    m = ChatMessage.create message: params[:message], user: user
    ActionCable.server.broadcast 'chat_channel', content: {message: params[:message], user: user, curr: @current_user.name, created_at: m.created_at}
    respond_to do |format|
      format.js
    end

  end

  def current
    render json: {name: User.find_by_id(cookies.encrypted['_ua_session']['user_id']).name}
  end
end
