class KitsController < ApplicationController

  require 'date'

  include KitsHelper
  include NodesHelper
  include WorkflowsHelper

  # before_action :authenticate
  # before_action :task_admin, :only => [ :get_message_from_journal, :fix_floating_kits, :create_kits_from_kits_tab ]
  skip_before_action :verify_authenticity_token, only: [ :get_time_spent, :create_kits_from_kits_tab ]
  before_action :authenticate, except: [ :create_kits_from_kits_tab ]
  before_action :task_admin, :only => [ :get_message_from_journal, :fix_floating_kits ]
  before_action :admin_user, :only => [ :set_kits_done, :set_kits_broken, :index ]
  before_action :lead_annotator_user, only: [ :show, :change_kit_state, :management ]

  def task
    respond_to do |format|
      format.html do
        flash[:error] = "See Projects / Tasks / Kits below"
        redirect_to root_path
      end
      format.json do
        @task = Task.find params[:id]
        render json: (
          if task_admin?
            # @state = params[:state]
            # @title = "Kits for #{@task.name}"
            @task_user = TaskUser.where( task_id: @task, user_id: current_user.id ).first
            get_kits
                # render json: {"aaData" => @kits}
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  def undo
    respond_to do |format|
      format.json do
        render json: Annotation.includes(:node_value).where(kit_id: params[:id]).order(:id).map { |x|
          {
            id: x.id,
            transaction_id: x.transaction_id,
            parent_id: x.parent_id,
            user_id: x.user_id,
            task_id: x.task_id,
            tree_id: x.tree_id,
            iid: x.iid,
            message: x.message,
            value: x.node_value.tvalue
          }
        }
      end
    end
  end

  def set_kits_done
    @task = Task.find params[:task][:id]
    Kit.where(:task_id => @task.id, :state => 'unassigned').each do |tk|
      tk.update(:state => 'done')
    end

    flash[:success] = "Marked all the kits for #{@task.name} as done"
    redirect_to project_task_path(@task.project, @task)
  end

  #this action fixes all of the floating kits for a particular task by moving them to another state (unassigned or broken typically)
  def fix_floating_kits
    @task = Task.find(params[:task])
    new_state = params[:new_state]
    Kit.where(:task_id => @task.id, :state => 'assigned').each do |kit|
      taskuser = TaskUser.kit_taskuser(kit.id).first
      if !taskuser || !User.exists?(taskuser.user_id)
        if new_state == 'broken'
          kit.state = new_state
          kit.meta['broken_comment'] = "broken by #{current_user.name} through floating kit fix process"
        else
          kit.state = new_state
        end
        kit.save!
      end
    end
    flash[:success] = "Successfully moved the floating kits for #{@task.name} to state => #{new_state}"
    redirect_back fallback_location: root_path
  end

  def change_kit_state
    @newState = kit_params[:state]
    @kit = Kit.find_by_uid kit_params[:uid]
    originalState = @kit.state
    if @newState == 'broken'
      @kit.state = 'broken'
      @kit.meta['broken_comment'] = "marked as broken by #{current_user.name}"
    else
      @kit.state = @newState
      flash[:success] = "Kit uid #{@kit.uid} state updated to #{@newState}"
    end
    @kit.save!
    #remove the kit from the taskuser if the original state was unassigned
    if originalState == 'assigned'
      if TaskUser.kit_taskuser(@kit.uid).count > 0
        taskuser = TaskUser.kit_taskuser(@kit.uid).first
        taskuser.kit_oid = nil
        taskuser.state = 'needs_kit'
        taskuser.save
      end
    end
    redirect_back fallback_location: root_path
  end

  def get_time_spent
    @kit = Kit.find_by_uid params[:uid]
    puts @kit.time_spent if @kit
    respond_to do |format|
      format.json do
        render :json => { :type => 'success', :message => "#{@kit.time_spent}"}
      end
      format.html do
        redirect_to root_path
      end
    end
  end

  def trouble
    @kit = Kit.find_by_uid params[:uid]
    UserMailer.trouble(@kit, current_user).deliver_now
    respond_to do |format|
      format.json do
        render :json => { :type => 'success', :message => "#{@kit.uid}"}
      end
    end
  end

  def change_time_spent
    @kit = Kit.find_by_uid params[:uid]
    if @kit
      @kit.time_spent = params[:time_spent].to_i
      @kit.save
    end
    respond_to do |format|
      format.json do
        render :json => { :type => 'success', :message => "set time_spent of #{@kit.uid} to #{@kit.time_spent}"}
      end
      format.html do
        redirect_to root_path
      end
    end
  end

  def management
    @title = "Kit Management"
    @tasks = Task.all
    @states = UserDefinedObject.where(:name => 'kit_states').first["object"].split
  end

  def index

  end
  def get
    @kit = Kit.find_by_uid(params[:uid])
    add_meta_values_to_kit
    if params[:task_user_id] == 'readonly'
      elaborate_root_helper unless params[:mode] == 'two'
    else
      task_user = TaskUser.find params[:task_user_id]
      raise 'wrong user' unless task_user.user == @current_user or params[:editor] == 'true'
      elaborate_root_helper task_user, task_user.state unless params[:mode] == 'two'
    end
    respond_to do |format|
      format.json do
        @kit.view = 'open' if @kit.view.nil? or @kit.view == ''
        @kit.meta['constraints'] = {}
        @kit.kit_type.constraints.each do |k, v|
          @kit.meta['constraints'][k] = (v == '' ? true : v)
        end
        # @kit.meta['constraints']['rtl'] = true if LDCI::CONFIG[:rtl] and @kit.source[:uid] and LDCI::CONFIG[:rtl].include?(@kit.source[:uid].split('_').first) and @kit.source[:uid] !~ /\.eng/
        hash = @kit.to_hash(false, 'deep', params[:editor])
        # unprotect_annotations hash['tree'] if @kit.task_id.in? protected_task_ids
        hash['other_task_user_id'] = get_other_task_user_id
        hash['game_params'] = @kit.task.game_variant ? @kit.task.game_variant.meta : {}
        hash['task_meta'] = @kit.task.meta 
        # if params[:iid]
        #   if params[:iid] == 0
        #     hash['tree'] = @kit.tree.tree.to_client_hash
        #   else
        #     node = Nd.where(tree_id: @kit.tree_id, iid: params[:iid]).first
        #     node.initialize_from_sql nil, @kit.tree, @kit.tree.class_def.inverted_grammar
        #     hash['tree'] = node.to_client_hash
        #   end
        # end
        render :json => hash
      end
    end
  end

  def get_other_task_user_id
    workflow = @kit.task.workflow
    if false #workflow.type == "Workflows::CaceTopicDevDataScouting"
      TaskUser.where( task_id: (Task.where(workflow_id: workflow.id).pluck(:id) - [ @kit.task_id ]).first, user_id: @kit.user_id ).pluck(:id).first
    else
      nil
    end
  end

  def unlock_tree
    @kit = Kit.find_by_id params[:id]
    response = { done: 'failure' }
    if @kit.tree.locked == current_user.id || current_user.admin?
      @kit.tree.update(locked: nil)
      response[:done] = 'success'
    end
    respond_to do |format|
      format.html
      format.json { render json: response }
    end
  end

  def show
    id = params[:id]
    if id.length == 24
      @kit = Kit.find_by_uid params[:id]
    else
      @kit = Kit.find_by_id params[:id]
    end
    @task_user = TaskUser.where( task_id: @kit.task_id, user_id: current_user.id).first
    @kit_types = KitType.all
    # redirect_to "/workflows/workflows/#{task.workflow_id}/read_only/#{kit.uid}", :only_path => true
    if params[:open]
      source = Source.where(id: params[:open].to_i).first
      @kit.source_uid = source.uid
      @kit.source[:uid] = source.uid
      @kit.source[:id] = source.uid
      @kit.source[:filename] = params[:filename]
      @kit.save!
    end
    if params[:s3]
      uid = params[:s3]
      @kit.source_uid = uid
      @kit.source[:uid] = uid
      @kit.source[:id] = uid
      @kit.source[:filename] = params[:filename]
      @kit.save!
    end
    if params[:goto]
      @kit.destroy
      Kit.find(params[:goto]).update(state: :assigned)
      @task_user.update( state: 'needs_kit' )
    end
    respond_to do |format|
      format.html
      format.json { render json: @kit }
    end
  end

  def kits_new
    if params[:open] or params[:s3]
      user_id = current_user.id
      task_id = params[:task_id].to_i
      kit = Kit.new
      kit.user_id = user_id
      kit.task_id = task_id 
      kit.kit_type_id = Task.find(task_id).kit_type_id
      kit.state = 'unassigned'
      # task_user = TaskUser.where( task_id: task_id, user_id: current_user.id).first
      # @kit_types = KitType.all
      # # redirect_to "/workflows/workflows/#{task.workflow_id}/read_only/#{kit.uid}", :only_path => true
    end
    if params[:open]
      source = Source.where(id: params[:open].to_i).first
      kit.source_uid = source.uid
      kit.source[:uid] = source.uid
      kit.source[:id] = source.uid
      kit.source[:filename] = params[:filename]
      kit.save!
    end
    if params[:s3]
      uid = params[:s3]
      kit.source_uid = uid
      kit.source[:uid] = uid
      kit.source[:id] = uid
      kit.source[:filename] = params[:filename]
      kit.save!
    end
    if params[:goto]
      kit = Kit.find(params[:goto])
      kit.update(state: :unassigned, user_id: current_user.id)
      # @task_user.update( state: 'needs_kit' )
    end
    respond_to do |format|
      format.html
      format.json do
        render json: {
          id: kit.id,
          uid: kit.uid,
          user_id: kit.user_id
        }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      format.json do
        @kit = Kit.find_by_id params[:id]
        @task = @kit.task
        render json: (
          if not task_admin?
            { error: "Only a task admin can edit the kit." }
          elsif @kit.update kit_params
            @kit
          else
            { error: @kit.errors.full_messages }
          end
        )
      end
    end
  end

  def duration
    respond_to do |format|
      format.json do
        kit = Kit.find_by_uid params[:kit_uid]
        render json: (
          v = KitValue.where(kit_id: kit.id, key: :duration).first_or_create
          v.update(value: params[:duration])
          { ok: params[:duration] }
        )
      end
    end
  end
  
  def create_kits_from_kits_tab
    respond_to do |format|
      format.json do
        @task ||= Task.find params[:task_id]
        r = params[:kits].map do |x|
          uid = x['docid']
          kit = @task.create_default_kit
          kit.source = { uid: uid, id: uid, filename: uid }
          kit.source_uid = uid
          kit.user_id = x['user_id']
          kit.save!
          kit.id
        end
        render json: (
          r
        )
      end
    end
  end
  
  def all
    respond_to do |format|
      format.json do
        kits = Kit.includes(tree: :class_def).where(task_id: params[:task_id], state: :done).where('tree_id is not null').to_a
        all_nodes = {}
        Node.includes(:node_value).where(tree_id: kits.map(&:tree_id), current: true).order(:index).each do |node|
          all_nodes[node.tree_id] ||= []
          all_nodes[node.tree_id] << node
        end
        o = kits.map { |x| x.transcript(all_nodes[x.tree_id]) }
        render json: o
      end
    end
  end
  
  private

  def kit_params
    params.require(:kit).permit(:meta, :user_id, :task_id, :kit_type_id, :uid, :state, :source, :broken_comment, :tree_id, :kit_batch_id, :not_user_id, :time_spent)
  end

  def elaborate_root_helper(task_user=nil, original_state='has_kit')
    begin
      if @kit.tree and @kit.tree.tree
        @kit.bootstrap_mode = @kit.tree.class_def.bootstrap_mode
        @kit.tree.elaborate_root *user_helper
      end
    rescue StandardError => e
      #on random errors post kit assignment, reset the user to be in the needs_kit state
      goto_state task_user, 'needs_kit' if task_user and (original_state == 'needs_kit' or original_state.nil?)
      raise e#raise the exception again so that it can be caught and handled in the application controller
    end
  end

  def add_meta_values_to_kit
    return
    @kit.kit_type.meta.each do |k, v|
      raise unless k =~ /^\w+$/
      case k
      when 'root1'
        next
      when 'source'
        if v.length > 0        # v = '{}' if v == ''
          @kit.source = JSON.parse v
        else
          @kit.source = {} unless @kit.source
        end
        next
      end
      #eval "@kit.#{k} = v" if @kit.respond_to? k
      @kit.send("#{ k }=", v) if @kit.respond_to? k
    end
  end

  def task_admin
    @task = params[:id] ? Task.find(params[:id]) : (params[:task] ? Task.find(params[:task]) : Task.find(params[:task_id]))
    redirect_to(root_path) unless task_admin?
  end

  def get_kits
    # Kit.includes(:user).where(:task_id => @task.id, :state => @state).map do |kit|
    Kit.includes(:user, :kit_states, :kit_values).where(:task_id => @task.id).map do |kit|
      {
        id: kit.id,
        uid: kit.uid,
        state: kit.state,
        link: get_link_to_kit(kit),
        source_uid: get_kit_source(kit),
        continue: get_link_to_continue(kit),
        user: get_kit_username(kit),
        # get_reassign_link(kit),
        broken_comment: get_broken_comment(kit),
        updated_at: get_kit_updated(kit),
        dual_id: kit.dual_id,
        # duration: kit.kit_values.where(key: :duration).first&.value.to_f
        duration: kit.kit_values.select { |x| x.key == 'duration' }.first&.value.to_f
      }
    end
  end

  def get_link_to_kit(kit)
    "/workflows/#{@task.workflow_id}/read_only/#{kit.uid}"
  end

  def get_link_to_continue(kit)
    @state == 'assigned' && @task_user ? view_context.link_to('continue', "/workflows/#{@task.workflow_id}/work/#{@task_user.id}?kit_id=#{kit.id}") : 'n/a'
  end

  def get_kit_source(kit)
    (kit.source[:uid] || kit.source['uid']) || "none"
  end

  def get_kit_username(kit)
    kit.user ? kit.user.name : 'none'
  end

  def get_reassign_link(kit)
    "<div class=\"reassign_kit modal-trigger\" kit_id=\"#{kit.uid}\">reassign</div>"
  end

  def get_broken_comment(kit)
    @state == 'broken' ? kit.broken_comment : "n/a"
  end

  def get_kit_updated(kit)
    kit.updated_at.getlocal
  end

end
