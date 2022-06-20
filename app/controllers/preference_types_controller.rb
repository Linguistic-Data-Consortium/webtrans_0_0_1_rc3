class PreferenceTypesController < ApplicationController
  before_action :lead_annotator_user

  def new
    redirect_to preference_types_path
  end

  def index
    @title = "All preference types"
    @preference_types = PreferenceType.all
    @tasks = Task.all
    @preference_type = PreferenceType.new
  end

  def edit
    @preference_type = PreferenceType.find(params[:id])
    redirect_to @preference_type
  end

  def show
    @preference_type = PreferenceType.find(params[:id])
    @title = @preference_type.name
  end

  def create
    @preference_type = PreferenceType.new(preference_type_params)
    if (@preference_type.save)
      flash[:success] = "New preference type: #{@preference_type.name} created"
      redirect_back(fallback_location: root_path)
    else
      flash[:error] = @preference_type.errors.full_messages.join(", ")
      redirect_back(fallback_location: root_path)
    end
  end

  def update
    @preference_type = PreferenceType.find(params[:id])
    if @preference_type.update(preference_type_params)
      flash[:success] = "Preference type #{@preference_type.name} updated"
    else
      flash[:error] = @preference_type.errors.full_messages.join(", ")
    end
    redirect_back(fallback_location: root_path)
  end

  def destroy
    pname = PreferenceType.find(params[:id]).name
    PreferenceType.find(params[:id]).destroy
    flash[:success] = "Preference type: #{pname} has been deleted."
    redirect_back(fallback_location: root_path)
  end

  private

  def preference_type_params
    params.require(:preference_type).permit(:task_id, :name, :values)
  end

end

