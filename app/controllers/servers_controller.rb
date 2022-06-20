class ServersController < ApplicationController

  # before_action :authenticate
  # before_action :admin_user, :only => :destroy
  # before_action :lead_annotator_user, :only => [ :new, :create ]
  # before_action :project_owner, :only => [ :update ]
  # before_action :project_member, :only => :show

  def index
    @init = true if Server.count == 0
    if @init
      init
      redirect_to root_path
    end
  end

  # def show
  #   @project = Project.includes( :tasks ).find(params[:id])
  #   @title = @project.name

  #   #for the new task partial
  #   @workflows = Workflow.all_newest_first
  #   @kit_types = KitType.all_newest_first
  #   @task = Task.new
  #   @available_kit_counts = Kit.where( state: 'unassigned', task_id: @project.tasks.pluck(:id) ).group(:task_id).count
  #   @project_owner_bool = @project.owner?(current_user) || admin?
  #   @project_admin_bool = @project.admin?(current_user) || @project_owner_bool
  #   @project_users = @project.project_users.includes(:user)
  #   @current_user_project_user = @project_users.select { |x| x.user_id == @current_user.id }.first
  #   @current_user_task_ids = TaskUser.where( task_id: @project.tasks.map(&:id), user_id: @current_user.id ).pluck(:task_id)
  # end

  # def new
  #   redirect_to projects_path
  # end

  def create
    @server = Server.new server_params
    if @server.save
      if Server.count == 1
        init
        flash[:success] = "Initialized"
        redirect_to root_path
      else
        flash[:success] = "New server: #{@server.name} created"
        redirect_to @server
      end
    else
      flash[:error] = @server.errors.full_messages.join(", ")
      redirect_back(fallback_location: root_path)
    end
  end

  # def edit
  #   @project = Project.find(params[:id])
  #   redirect_to @project
  # end

  # #only used for updating the name
  # def update
  #   @project = Project.find(params[:id])
  #   @project.name = params[:project][:name]
  #   save_project("Name updated to #{@project.name}.")
  #   redirect_back
  # end

  # def destroy
  #   projectname = Project.find(params[:id]).name
  #   Project.find(params[:id]).destroy
  #   flash[:success] = "Project: #{projectname} has been deleted."
  #   redirect_back
  # end

  def get_tools
    get_toolsp
  end

  def glg
  end

  private

  def server_params
    params.require(:server).permit(:name, :glg)
  end

  def init
    # Workflow.where(name: 'OnTheFly', user_states: 'needs_kit,has_kit').first_or_create
    # Workflow.where(name: 'Orderly', user_states: 'needs_kit,has_kit').first_or_create
    # get_toolsp
    # KitType.create(name: 'test', node_class_id: NodeClass.find_by_name('CaceTopicDev:Root').id, javascript: 'cace_topic_dev')
    # KitType.create(name: 'test2', node_class_id: NodeClass.find_by_name('RichEre:Root').id, javascript: 'rich_ere')
    # NodeValue.where(id:0).first_or_create
  end

  def get_toolsp
    get_toolspp '/nieuw'
  end

end
