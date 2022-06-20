class GroupUsersController < ApplicationController
  before_action :authenticate
  before_action :admin_user

  def create
    respond_to do |format|
      format.json do
        if admin?
          group = Group.find params[:group_id]
          user = User.find params[:user_id]
          group.users << user
          render json: { ok: "#{user.name} has been added to the group: #{group.name}" }
        else
          render json: { error: 'permission denied' }
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        if admin?
          gu = GroupUser.find params[:id]
          group = gu.group
          group.delete_user gu.user
          render json: { ok: "#{gu.user_name} has been removed from the group: #{group.name}" }
        else
          render json: { error: 'permission denied' }
        end
      end
    end
  end

end
