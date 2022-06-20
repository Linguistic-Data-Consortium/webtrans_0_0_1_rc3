class GroupsController < ApplicationController

  before_action :authenticate

  def users_not_in
    respond_to do |format|
      format.json { render json: Group.find(params[:id]).users_not_in(params[:term]) }
    end
  end

  def index
    index_all model: Group, only: :admin
  end

  def show
    f = -> (x) { x.group_users.map { |x| { id: x.id, user_id: x.user_id, name: x.user_name } } }
    show_users model: Group, params: params, users: [ :group_users, f ], only: :admin
  end

  def create
    createj model: Group, params: group_params, only: :admin
  end

  def update
    updatej model: Group, p: params, params: group_params, only: :admin
  end

  def destroy
    destroyj model: Group, params: params, only: :admin
  end

  private

  def group_params
    params.require(:group).permit(:name)
  end

end
