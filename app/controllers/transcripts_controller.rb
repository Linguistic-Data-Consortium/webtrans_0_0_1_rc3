class TranscriptsController < ApplicationController
  before_action :authenticate
  before_action :admin_user
  
  def index
    @kit = Kit.find_by_uid(params[:uid])
  end
  
end
