class TaskUsersController < ApplicationController

  before_action :authenticate
  before_action :task_admin, :except => [ :get, :read_only, :create, :destroy, :update ]

  include ClassDefsHelper
  include NodesHelper

  def show
    respond_to do |format|
      format.json do
        if task_admin? # uses @task
          tu = TaskUser.find params[:id]
          render json: history(tu)
        else
          render json: { error: 'permission denied' }
        end
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        @task = Task.find params[:task_id]
        if task_admin? # uses @task
          user = User.find params[:user_id]
          @task.users << user
          render json: { ok: "#{user.name} has been added to #{@task.name}" }
        else
          render json: { error: 'permission denied' }
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        tu = TaskUser.find params[:id]
        @task = tu.task
        if task_admin? # uses @task
          @task.delete_user tu.user
          render json: { ok: "#{tu.user_name} has been removed from #{@task.name}" }
        else
          render json: { error: 'permission denied' }
        end
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        task_user = TaskUser.find params[:id]
        @task = task_user.task
        if task_admin? # uses @task
          response = []
          if params.has_key? :admin
            task_user.update(admin: params[:admin])
            response << "#{task_user.user_name} #{task_user.admin? ? "has been made" : "is no longer"} an admin of #{task_user.task_name}"
          end
          if params.has_key? :state
            # task_user.update(admin: params[:admin])
            task_user.goto_state params[:state]
            response << "#{task_user.user_name} set to state #{params[:state]}"
          end
          render json: { ok: response.join(',') }
        else
          render json: { error: 'permission denied' }
        end
      end
    end
  end

  #this action allows read only viewing of any kit for task admins and greater
  def read_only
    @workflow = Workflow.find params[:id]
    @kit = @workflow.read_only params[:kit_id]
    @task = @kit.task
    @project = @task.project
    @kit_type = @kit.kit_type
    kit_source_helper
    render 'workflows/work'
  rescue Workflow::TaskLockError => e
    redirect_to root_path, :flash => {:info => e.to_s}
  rescue Workflow::NoKitError => e
    redirect_to root_path, :flash => {:info => e.to_s}
  end

  # hook into specific workflows
  # 1. changes user's current task
  # 2. calls work method on workflow model
  # 3. renders view based on response from model

  def get
    task_user = TaskUser.find params[:id]
    @task = task_user.task
    @project = @task.project
    @workflow = @task.workflow
    if task_user.user != @current_user
      if admin?
        raise Workflow::ReadOnlyError, "read only"
      else
        raise Workflow::WorkError, 'wrong user'
      end
    end
    raise Workflow::TaskInactiveError, 'inactive' if @task.status == 'inactive'
    original_state = task_user.state
    #set the current_task_user_id if its different than the one being annotated on, set the state to paused for the previous taskuser
    current_user.update_current_task_user task_user
    raise Workflow::WorkError, 'your work is on hold' if task_user.state == 'hold'

    if params[:kit_id]
      @workflow.return_to_kit task_user, params[:kit_id]
    end

    task_user.goto_state 'needs_kit' if task_user.state == nil

    @kit = @workflow.work task_user

    raise Workflow::KitLockError, 'wrong user' if @kit.user_id != @current_user.id

    @kit_type = @kit.kit_type
    kit_source_helper
    # raise @kit.inspect
    respond_to do |format|
      format.html #{ render "kit_types/kit_type/#{@kit.kit_type.meta['template']}" }
      format.json { render json: @kit }
    end
    render 'workflows/work'
  rescue Workflow::KitLockError => e
    redirect_to user_path(@current_user), :flash => {:info => "Kit #{@kit.uid} is locked. Please try again"}
  rescue Workflow::TaskInactiveError => e
    redirect_to root_path, flash: { error: "That task is inactive." }
  rescue Workflow::ReadOnlyError => e
    redirect_to "/workflows/#{workflow.id}/read_only/#{task_user.kit_oid}"
  rescue Workflow::TaskLockError => e
    redirect_to user_path(task_user.user), :flash => {:info => "#{e.to_s}... Please try again"}
  rescue Workflow::WorkError => e
    redirect_to user_path(task_user.user), :flash => {:info => "#{e.to_s}... Please try again"}
  rescue Workflow::NoKitError => e
    task_user.goto_state 'needs_kit'
    redirect_to user_path(task_user.user), :flash => {:info => e.to_s}
  rescue Workflow::HoldError => e
    task_user.goto_state 'hold'
    redirect_to user_path(task_user.user), :flash => {:info => e.to_s}
  end
  
  def kit_source_helper
    if @kit.source[:uid]
      @source = Source.where(uid: @kit.source[:uid]).first
    elsif @kit.source[:id]
      @source = Source.where(id: @kit.source[:id]).first
    end
    if @source and @source.file
      @source.update(uid: @source.file.key) if @source.uid.nil?
      @kit.source[:uid] = @source.uid if @kit.source[:uid].nil?
      @manifest ||= {}
      @manifest[:urls] = { @source.uid => url_for(@source.file) }
    end
    @workflow.kit_source_helper @kit, @source, @manifest
    if @manifest and @manifest[:urls]
      @manifest[:urls].keys.each do |k|
        v = @manifest[:urls][k]
        @manifest[:urls][k] = url_for v.file if v.class == Source
      end
    end
    if @kit.source_uid and @source.nil?
      if @kit.source_uid =~ /^s3:/
        s3 = @kit.source_uid
      else
        s3 = 's3'
        if @task&.data_set&.name
          b = @task.data_set.name.split.first
          s3 << b
        end
      end
      @manifest = { urls: { @kit.source_uid => s3 } }
    end
  end
  
  def manifest_helper
    hash = @kit.task.game_variant ? @kit.task.game_variant.meta : {}
    dsid = hash['data_set']
    # dsid = 3
    if dsid
      ds = DataSet.find(dsid)
      if ds.name =~ /aws/
        x = ds.name.sub('aws','json')
        "//ldc-developers.s3.amazonaws.com/#{x}"
      else
        ds.spec.url
      end
    else
      nil
    end
  end

  private

  def task_admin
    #need to define @task so task_admin? in sessions_helper can work
    #uses the task :id for edit/update and the taskuser :task_id for create_tu/remove_tu
    @task = params[:task_id].nil? ? TaskUser.find(params[:id]).task : Task.find(params[:task_id])
    redirect_to(root_path) unless task_admin?
  end

  def task_admin2
    #need to define @task so task_admin? in sessions_helper can work
    #uses the task :id for edit/update and the taskuser :task_id for create_tu/remove_tu
    @task = params[:task_id].nil? ? TaskUser.find(params[:id]).task : Task.find(params[:task_id])
  end

  def elaborate_root_helper(task_user=nil, original_state='has_kit')
    begin
      if @kit.tree and @kit.tree.tree
        @kit.bootstrap_mode = @kit.tree.class_def.bootstrap_mode
        @kit.tree.elaborate_root *user_helper
      end
    rescue StandardError => e
      #on random errors post kit assignment, reset the user to be in the needs_kit state
      task_user.goto_state 'needs_kit' if task_user and (original_state == 'needs_kit' or original_state.nil?)
      raise e#raise the exception again so that it can be caught and handled in the application controller
    end
  end

  def history(tu)
    return { ok: [] } if tu.versions.length < 2
    {
      ok: (tu.versions.all[1..-1].map { |x|
        y = YAML.load(x.object)
        [
          y['updated_at'],
          (y['state'] || '').ljust(10, ' '),
          (y['kit_oid'] || (' '*24)),
          x.whodunnit
        ].join(' ')
      } + [[tu.updated_at, tu.state, tu.kit_oid].join(' ')] ).join("\n")
    }
  end

end
