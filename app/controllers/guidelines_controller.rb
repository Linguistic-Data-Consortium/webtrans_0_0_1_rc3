class GuidelinesController < ApplicationController

  before_action :authenticate
  before_action :admin_user

  def index
    @current_guideline = Guideline.last
    @new_guideline = Guideline.new
    render 'edit'
  end


  def create
    @guideline = Guideline.new guideline_params
    if @guideline.save
      @guideline.update(url: url_for(@guideline.file)) if @guideline.file.attached?
      flash[:success] = "Guidelines #{@guideline.name} successfully submitted"
      unless params[:task].blank?
        t = Task.find_by_id params[:task]
        unless t.nil?
          meta = t.meta
          meta[:task_guidelines_link] = guideline_params[:url]
          flash[:success] = flash[:success]+" and assigned to task #{t.name}" if t.update(meta: meta)
          guidelines_guides = Guide.where(name: "Guidelines_task_"+t.id.to_s)
          guidelines_guides.update_all(complete: false, currentstep: guidelines_guides.first.firststep||0)
        end
      end
    else
      flash[:error] = @guideline.errors.full_messages.join(", ")
    end
    redirect_to '/guidelines'
  end


  private

  def guideline_params
    params.require(:guideline).permit(:name, :url, :version, :file)
  end


end
