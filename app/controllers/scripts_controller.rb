class ScriptsController < ApplicationController

  before_action :authenticate

  def index
    index_own model: Script
  end

  def show
    script = Script.find(params[:id])
    respond_to do |format|
      format.json do
        render json: (
          if script.user_id == current_user.id
            script.attributes
          elsif script.xgroup_id and script.xgroup.users.pluck(:id).include?(current_user.id)
            script.attributes
          else
            { error: 'Permission denied.' }
          end
        )
      end
      format.html do
        if script.user_id == current_user.id
          # script.attributes
        elsif script.xgroup_id and script.xgroup.users.pluck(:id).include?(current_user.id)
        else
          @error = { error: 'Permission denied.' }
        end
      end
    end
  end

  # what's a good permissions policy for this?
  def create
    createj model: Script, params: script_params, only: :any, own: true
  end

  def update
    updatej model: Script, p: params, params: script_params, only: :own
  end

  def destroy
    destroyj model: Script, params: params, only: :own
  end

  private

  def script_params
    params.require(:script).permit(:name, :user_id, :description, :code, :rgroup_id, :wgroup_id, :xgroup_id)
  end

end
