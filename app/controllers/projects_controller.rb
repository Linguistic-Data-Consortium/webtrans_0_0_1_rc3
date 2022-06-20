class ProjectsController < ApplicationController

  before_action :authenticate
  before_action :admin_user, :only => :destroy
  before_action :lead_annotator_user, :only => [ :create, :users_not_in_project]
  # before_action :project_member, :only => :show
  after_action { flash.discard if request.xhr? }

  include UsersHelper
  # include MarkdownAdapter

  def users_not_in_project
    @project = Project.find(params[:id])
    userids = @project.users.map{ |x| x.id }
    @users = User.all.order(:name).where("name LIKE ?", "%#{params[:term]}%").where.not(id: userids).map{ |x| {name: x.name, id: x.id, project_id: @project.id.to_s } }
    respond_to do |format|
      format.json { render json: @users }
    end
  end

  def index
    respond_to do |format|
      format.json do
        if lead_annotator?
          projects = Project.sorted.all
        else
          projects = @current_user.sorted_projects
        end
        task_counts = Task.group(:project_id).count
        render json: (
          projects.map do |project|
            {
              id: project.id,
              name: project.name,
              task_count: task_counts[project.id]
            }
          end
        )
      end
    end
  end


  def show
    respond_to do |format|
      format.json do
        project = Project.includes( :tasks ).find(params[:id])
        render json: (
          if project.member?(@current_user) || lead_annotator?
            title = project.name
            #for the new task partial
            @workflows = Workflow.all.order(:id) #.all_newest_first
            @kit_types = KitType.all_newest_first
            @languages = Language.all
            available_kit_counts = Kit.where( state: 'unassigned', task_id: project.tasks.pluck(:id) ).group(:task_id).count
            project_owner_bool = project.owner?(current_user) || admin?
            project_admin_bool = project.admin?(current_user) || project_owner_bool
            project_users = project.project_users.includes(:user).map do |x|
              {
                id: x.id,
                user_id: x.user_id,
                name: x.user_name,
                owner: x.owner,
                admin: x.admin
              }
            end
            # @current_user_project_user = project_users.select { |x| x.user_id == @current_user.id }.first
            # @current_user_task_ids = TaskUser.where( task_id: project.tasks.map(&:id), user_id: @current_user.id ).pluck(:task_id)
            {
              id: project.id,
              name: title,
              project_owner_bool: project_owner_bool,
              project_admin_bool: project_admin_bool,
              tasks: project.tasks.map { |x|
                {
                  id: x.id,
                  name: x.name,
                  available_kit_count: (available_kit_counts[x.id] || 0),
                  source_uid: x.meta['docid']
                }
              },
              project_users: project_users
            }
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        render json: (
          project = Project.new project_params
          if project.save
            ProjectUser.create(project_id: project.id, user_id: @current_user.id, owner: true, admin: true)
            project
          else
            { error: project.errors.full_messages }
          end
        )
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        @project = Project.find(params[:id])
        render json: (
          if not project_owner? # uses @project
            { error: "Only the project owner or an administrator can edit the project." }
          elsif @project.update project_params
            @project
          else
            { error: @project.errors.full_messages }
          end
        )
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        project = Project.find(params[:id])
        project.destroy
        render json: { deleted: "Project: #{project.name} has been deleted." }
      end
    end
  end

  def get_tasks
    @project = Project.find(params[:id])
    @tasks = @project.tasks
  end
  
  def respond_with_project
    @project = Project.find(params[:project][:id])
    respond_to do |format|
      format.json { render json: { project: @project } }
    end
  end

  def add_user_to_project_and_task
    if current_user
      @project = Project.find(params[:project_id])
      @task = Task.find(params[:task_id])
      @kits_available_by_task = Kit.where( state: :unassigned, user_id: [ current_user.id, nil ] ).group(:task_id).count
      # check here if more permissions would be needed in the future
      if true
        if !@project.users.include?(current_user)
          @project.users << current_user
        end
        if !@task.users.include?(current_user)
          @task.users << current_user
        end
        tuser = TaskUser.where(task: @task, user: current_user).first
        if new_kits_available?(tuser) or tuser.has_kit_oid? or @task.workflow.name == 'OnTheFly'
          redirect_to "/workflows/#{tuser.id}/work/#{@task.workflow_id}"
        else
          redirect_back(fallback_location: root_path)
        end
      end
    else
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :title, :subtitle, :about)
  end

end
