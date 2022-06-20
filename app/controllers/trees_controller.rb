class TreesController < ApplicationController
  before_action :authenticate
  before_action :admin_user
  
  def index
  end
  
end
