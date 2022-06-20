class PreferenceSettingsController < ApplicationController

  before_action :correct_user, :except => [:edit, :show, :update, :destroy, :index]
  before_action :correct_owner, :only => [:edit, :show, :update, :destroy]
  before_action :authenticate, :only => [:index]

  #TODO require user to be either admin or matching the current user id

  def new
    redirect_to preference_settings_path
  end

  def index
    @title = "Preference Settings"
    if admin?
      @preference_settings = PreferenceSetting.all
    else
      @preference_settings = PreferenceSetting.where(user: current_user).all
    end
    @users = User.all
    @preference_types = PreferenceType.all
    @preference_setting = PreferenceSetting.new
  end

  def edit
    @preference_setting = PreferenceSetting.find(params[:id])
    redirect_to @preference_setting
  end

  def show
    @preference_setting = PreferenceSetting.find(params[:id])
    @title = "#{@preference_setting.user_name} #{@preference_setting.preference_type_name}"
  end

  def create
    ps_params = preference_setting_params
    @settings = PreferenceSetting.where( :user_id => ps_params[:user_id], :preference_type_id => ps_params[:preference_type_id] ).first_or_create
    # TODO: destroy setting if value is nil?
    @settings.value = ps_params[:value]
    if @settings.save
      flash[:success] = "User #{@settings.user_name} changed #{@settings.preference_type_name} to #{@settings.value}"
    else
      flash[:error] = @settings.errors.full_messages.join(', ')
    end
    redirect_back(fallback_location: root_path)
  end

  def update
    @preference_setting = PreferenceSetting.find(params[:id])
    if @preference_setting.update(preference_setting_params)
      flash[:success] = "Preference set to #{@preference_setting.value}"
    else
      flash[:error] = @preference_setting.errors.full_messages.join(", ")
    end
    redirect_back(fallback_location: root_path)
  end

  def destroy
    settings = PreferenceSetting.find(params[:id])
    settings.destroy
    flash[:success] = "User #{settings.user_name} setting for #{settings.preference_type_name} deleted"
    redirect_back(fallback_location: root_path)
  end

  def correct_user
    return if admin?
    if preference_setting_params[:user_id]
      return if admin_or_current_user_id? preference_setting_params[:user_id]
      flash[:error] = "You do not have permission to change settings for this user"
      redirect_to root_path
    else
      flash[:error] = "Non-admins must specify user_id"
      require 'pry'; binding.pry
      redirect_to root_path
    end
  end

  def correct_owner
    return if admin?
    if params[:id]
      return if admin_or_current_user_id? PreferenceSetting.find(params[:id]).user_id
      flash[:error] = "You do not have permission to change this setting"
      redirect_to root_path
    else
      flash[:error] = "No preference setting specified"
      redirect_to root_path
    end
  end

  private

  def preference_setting_params
    params.require(:preference_setting).permit(:user_id, :preference_type_id, :value)
  end
end

