class TasksController < ApplicationController

  before_action :authenticate
  before_action :task_admin, :only => [ :reassign_many_kits, :respond_with_task, :recreate ]
  after_action { flash.discard if request.xhr? }

  include NodesHelper
  include TasksHelper
  # include MarkdownAdapter

  helper_method :render_content

  # def index
  #   if params[:user_id]
  #     @title = "Tasks for User #{params[:user_id]}"
  #     @tasks = User.find(params[:user_id]).tasks.includes(:project)
  #   else
  #     @title = "All tasks"
  #     @tasks = Task.includes(:project).all
  #   end
  #   respond_to do |format|
  #     format.html
  #     format.json { render json: @tasks.map(&:id) }
  #   end
  # end

  def show
    respond_to do |format|
      format.json do
        @task = params[:task_id].nil? ? Task.find(params[:id]) : Task.find(params[:task_id])
        if @task.workflow_id.nil?
          @task.update(workflow_id: Workflow.find_by_name('OnTheFly').id)
        end
        if @task.kit_type_id.nil?
          kt = KitType.where(name: "KitType for Task #{@task.id}").first_or_create
          @task.update(kit_type_id: kt.id)
        end
        render json: (
          if task_admin? # uses @task
            if params[:force_kit_type]
              Kit.where(task_id: @task.id).update_all(kit_type_id: @task.kit_type_id)
            end
            @title = @task.name
            @states = @task.workflow ? @task.workflow_user_states.split(',') : []
            @kit_state_count_map = Hash.new
            @kit_states = ['assigned', 'unassigned', 'broken', 'hold', 'excluded', 'done', 'unassigned'] #UserDefinedObject.where(name: "kit_states").first.object.split(" ")
            @languages = Language.all
            @preference_type = PreferenceType.new
            @preference_type.task = @task
            @preference_types = @task.preference_types
            @preference_settings = @task.preference_settings_for_user(current_user)



            @bucket = @task&.data_set&.name&.split&.first || ''
            @bucket_size = @bucket == '' ? 0 : helpers.bucket_size(@bucket)
            if params[:data_set_id] == 'true'
              @task = @task.data_set.files.map { |x| { id: x.blob.id, fn: x.blob.filename.to_s } }
            end



            @kit_users = User.where( :id => Kit.where(:task => @task).pluck(:user_id) )
            Kit.where(task_id: @task.id).pluck(:state).push("done", "unassigned", "assigned", "broken").uniq.each do |state|
              @kit_state_count_map[state] = Kit.where(:task_id => @task.id, :state => state).count
            end
            @floating_kits = @task.floating_kits #gather any floating kits into a list for later use
            @available_kits = @task.available_kits #gather a list of available kits to display
            task_users = @task.task_users.map do |x|
              {
                id: x.id,
                user_id: x.user_id,
                name: x.user_name,
                state: x.state,
                admin: x.admin
              }
            end
            if false # @task.kit_type and @task.kit_type.meta['root']
              class_def = ClassDef.find_by_name(@task.kit_type.meta['root'].split(':').first)
              ann = Annotation.where(task_id: @task.id).last
              o = UserDefinedObject.where(id: 49).first
              if o and o.object # production
                o = YAML.load o.object
              else # dev
                o = { class_def_ids: { 516 => { next: 1245898 } } }
              end
              o = o[:class_def_ids][class_def.id]
              if o
                ann2 = Annotation.where(task_id: @task.id).where("id < #{o[:next]}").last
                if ann2
                  diff = (ann.created_at-ann2.created_at)/60/60
                end
              end
            else
              class_def = false
            end
            tasks = @task.project.tasks.select { |x| x.id != @task.id }.map do |x|
              {
                id: x.id,
                name: x.name
              }
            end
            o = {
              id: @task.id,
              name: @title,
              status: @task.status,
              workflow_id: @task.workflow_id,
              workflows: Workflow.all.map { |x| { id: x.id, name: x.name } },
              kit_type_id: @task.kit_type_id,
              kit_types: KitType.all.map { |x| { id: x.id, name: x.name } },
              data_set_id: @task.data_set_id,
              data_sets: DataSet.all.map { |x| { id: x.id, name: x.name } },
              # project_owner_bool: @project_owner_bool,
              task_admin_bool: task_admin?,
              # tasks: @project.tasks.map { |x| { id: x.id, name: x.name } },
              task_users: task_users,
              class_def: (class_def ? true : false),
              tables: (class_def ? class_def.views_created : nil),
              ann: (ann ? ann.created_at : false),
              ann2: (ann2 ? ann2.created_at : false),
              diff: (diff || false),
              source_uid: @task.meta['docid'],
              meta: @task.meta,
              features: Feature.where(category: 'task').map(&:attributes),
              tasks: tasks,
              bucket: @bucket,
              bucket_size: @bucket_size
            }
            if params[:existing] == 'true'
              Kit.includes(:user, :task).where(task_id: @task.id, user_id: current_user.id).map do |x|
                {
                  id: x.id,
                  uid: x.uid,
                  filename: x.source[:filename],
                  kit_user: x.user.name,
                  task_id: x.task_id,
                  task: x.task.name,
                  state: x.state,
                  name: x.done_comment
                }
              end
            else
              o
            end
          else
            { error: 'you must be a task admin to do that' }
          end
        )
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        render json: (
          @project = Project.find(params[:project_id])
          if not project_admin? # uses @project
            { error: "You must be a project admin to do that." }
          else
    # copy = task_params
    # create_params = copy
    # tokenOptions = ["counttype", "elimxml", "elimquotes", "targettext"]
    # tokenOptions.each { |x| create_params.delete(x) }
    # @task = Task.new create_params
    # tokenOptions.each do |x|
    #   if copy[x]
    #       @task.token_counting_method[x] ? @task.token_counting_method[x] = copy[x] : @task.token_counting_method.store(x, copy[x])
    #   end
    # end
    # 
    # if params[:fast]
    #   class_def_name = params.key?(:class_def_name) ? params[:class_def_name] : @task.name.dup
    #   class_def_name = class_def_name.gsub(/\W+/, '').capitalize
    #   @cd = ClassDef.where( name: class_def_name ).first_or_create
    #   root_class = NodeClass.where(:name => "#{@cd.name}:Root", :parent_id => NodeClass.find_by_name('Root').id, :children => "").first_or_create
    #   root_class.class_def = @cd
    #   root_class.save!
    #   if params[:list]
    #     list_class = NodeClass.where(:name => "#{@cd.name}:DefaultList", :parent_id => NodeClass.find_by_name('List').id, :children => "").first_or_create
    #     list_class.class_def = @cd
    #     list_class.save!
    #     root_class.children = list_class.name.split(':')[1] + '.' + list_class.name
    #     root_class.save!
    #     list_item_class = NodeClass.where(:name => "#{@cd.name}:DefaultListItem", :parent_id => NodeClass.find_by_name('Node').id, :children => "").first_or_create
    #     list_item_class.class_def = @cd
    #     list_item_class.save!
    #     list_class.children = list_item_class.name.split(':')[1] + '.' + list_item_class.name
    #     list_class.save!
    #   end
    #   kt = KitType.new( name: params.key?(:kit_type_name) ? params[:kit_type_name] : @task.name.dup, node_class_id: root_class.id, javascript: 'empty' )
    #   if params[:list]
    #     kt.constraints = {"manifest"=>"manifest", "web_audio"=>"web_audio", "audio1"=>"audio1"}
    #   end
    #   @task.kit_type = kt
    #   # workflow should come from params
    #   @task.workflow_id = Workflow.find_by_name('OnTheFly').id
    # end
    # 
    # @project = Project.find params[:project_id]
    # @task.project = @project
    # # @task.workflow_id = 1
    # # @task.kit_type_id = 1
    # if @task.save
    #   @project.tasks << @task
    #   flash[:success] = "New task #{@task.name} created in project #{@project.name}"
    #   respond_to do |format|
    #     format.html { redirect_to project_task_path(@project, @task)}
    #     format.json { render json: {task: @task, class_def: @cd} }
    #   end
            task = Task.new task_params
            if task.project_id.nil?
              task.project_id = @project.id
            end
            if task.workflow_id.nil?
              task.workflow_id = Workflow.find_by_name('OnTheFly').id
            end
            if task.kit_type_id.nil?
              id = NodeClass.where(name: 'SimpleTranscription:Root').first.id
              kt = KitType.where(name: "KitType for Task #{SecureRandom.hex(4)}", node_class_id: id).first_or_create
              kt.constraints['web_audio'] = 'web_audio'
              kt.constraints['show_source'] = 'show_source'
              kt.save
              task.kit_type_id = kt.id
            end
            if task.save
              kt.update(name: "KitType for Task #{task.id}") if kt
              task
            else
              { error: task.errors.full_messages }
            end
          end
        )
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        @task = params[:task_id].nil? ? Task.find(params[:id]) : Task.find(params[:task_id])
        render json: (
          if not task_admin? # uses @task
            { error: "You must be a task admin to do that." }
          elsif params[:meta]
            Feature.where(category: 'task').uniq.each do |x|
              if params[:meta].has_key? x.name
                if x.name == x.value
                  if params[:meta][x.name]
                    @task.meta[x.name] = x.name
                  else
                    @task.meta.delete x.name
                  end
                else
                  if params[:meta][x.name] and (params[:meta][x.name].class != String or params[:meta][x.name].length > 0)
                    @task.meta[x.name] = params[:meta][x.name]
                  else
                    @task.meta.delete x.name
                  end
                end
              end
            end
            # @task.meta['docid'] = params[:docid]
            if @task.save
              @task
            else
              { error: @task.errors.full_messages }
            end
          elsif @task.update task_params
            @task
          else
            { error: @task.errors.full_messages }
          end
        )
      end
    end
  end
    # if @task.update(task_params.except(:tokens).except(*tokenOptions).except(:meta))

  def destroy
    respond_to do |format|
      format.json do
        task = params[:task_id].nil? ? Task.find(params[:id]) : Task.find(params[:task_id])
        @project = task.project
        if not project_admin? # uses @project
          { error: "You must be a project admin to do that." }
        else
          task.destroy
          render json: { deleted: "Task #{task.name} deleted from project #{task.project_name}" }
        end
      end
    end
  end
  
  #action that displays a kit creation dialog, which is defined for each kit type
  def kit_creator
    @task = Task.find(params[:id])
    @task.help_video = 'help'
    @task.save!
    @kit_type = @task.kit_type
    # if @kit_type.respond_to? 'kit_generation_options'
    #   @tabs = @kit_type.kit_generation_options(@task)
    # else
    #   flash[:info] = "No Kit generation code exists for this task and kit type"
    #   redirect_back fallback_location: root_path
    # end
  end
  
  #action that uploads a file and stores in a directory specific to the project / task
  def file_upload
    task = Task.find params[:id]
    
    fileprefix = Rails.application.config.public_path
    publicpath = "#{fileprefix}/#{task.project_name}/#{task.name}"
    uploadedString = params['new_file'].read.force_encoding "utf-8"
    uploadedString.encode("utf-16le")
    uploadFile = StringIO.new uploadedString

    serverFileName = "#{publicpath}/#{Time.now}-#{params['new_file'].original_filename}";
    serverFile = File.open(serverFileName, "w+:utf-8") #need read and write.
    serverFile.write(uploadFile.read())
    serverFile.rewind #reading from it below.
    serverFile.close
    
    redirect_back fallback_location: root_path
  end
  
  #action that reassigns a single kit to a user, which means marking it as unassigned and adding the user_id into the kit
  def reassign_kit
    task = Task.find params[:id]
    kit = Kit.find_by_uid params[:kit]
    if kit.state == 'assigned'
      taskuser = TaskUser.kit_taskuser(kit.uid).first
      taskuser.update( kit_oid: '', state: 'needs_kit' ) if taskuser
    end
    
    if params[:user][:id].blank?
      kit.update(state: 'unassigned', user_id: nil)
    else
      user_id = params[:user][:id].to_i
      kit.update(state: 'unassigned', user_id: user_id)
    end
    
    flash[:success] = "kit: #{kit.uid} has been moved to unassigned and given user_id: #{user_id}"
    redirect_to project_task_path(task.project, task)
  end

  def reassign_many_kits
    respond_to do |format|
      format.json do
        selection_hash = {}
        update_hash = {}
        task = Task.find params[:id]
        uids = { success: [], error: [] }
        params[:uids].split(',').each do |uid|
          kit = Kit.find_by_uid(uid)
          if kit
            if params[:new_user]
              kit.user_id = params[:new_user].length > 0 ? User.find_by_name(params[:new_user]).id : nil
            end
            if params[:new_state]
              kit.state = params[:new_state]
            end
            if kit.save
              uids[:success] << "#{uid} modified"
            else
              uids[:error] << "#{uid} failed"
            end
          else
            uids[:error] << "#{uid} failed"
          end
        end
        render json: (
          {
            uids: uids
          }
        )
      end
    end
  end
 
 
  def get_users
    @task = Task.find(params[:id])
    @users = @task.users
  end

  def get_links
    @task = Task.find(params[:id])
  end

  def download
    file = Task.find(params[:id]).meta[params[:lid]]
    if !file.blank? && File.exist?(file)
      send_file file, :x_sendfile => true
    else
      flash[:error] = "File not accessible."
      redirect_back fallback_location: root_path
    end
  end

  private

  def task_params
    params[:task][:language_id] = Language.where( ref_name: params[:task][:language]).first.id if params[:task][:language] && Language.where( ref_name: params[:task][:language]).count > 0
    params[:task][:kit_type_id] = KitType.where(name: params[:task][:kit_type]).first.id if params[:task][:kit_type] && KitType.where(name: params[:task][:kit_type]).count > 0
    params[:task][:data_set_id] = DataSet.where(name: params[:task][:data_set]).first.id if params[:task][:data_set] && DataSet.where(name: params[:task][:data_set]).count > 0
    params[:task][:workflow_id] = Workflow.where(name: params[:task][:workflow]).first.id if params[:task][:workflow] && Workflow.where(name: params[:task][:workflow]).count > 0
    params.require(:task).permit(:fund_id, :cref_id, :status, :tokens, :counttype, :elimxml, :elimquotes,
      :targettext, :name, :workflow_id, :help, :kit_type_id, :data_set_id, :per_person_kit_limit, :check_count,
      :lock_user_id, :language_id, :task_type_id, :deadline,
      :start_user, :start_state, :end_user, :end_state, :uids,
      meta: [:lang_code, :production, :notes, :docid, :source_directory,
      :chat_room_link, :mail_list_link, :training_link, :task_guidelines_link, :schedule_session_link, :supervisor_link])
  end
  
  def task_admin
    #need to define @task so task_admin? in sessions_helper can work
    @task = params[:task_id].nil? ? Task.find(params[:id]) : Task.find(params[:task_id])
    unless task_admin?
      flash[:error] = "You must be a task admin to do that."
      redirect_to(root_path)
    end
  end
  
  def save_task(success_str)
    @task.save ? flash[:success] = success_str : flash[:error] = @task.errors.full_messages.join(", ")
  end

  def set_needs_kit_no_state_change(kits)
    kits.each do |kit|
      if kit.state == 'assigned'
        taskuser = TaskUser.kit_taskuser(kit.uid).first
        taskuser.update( kit_oid: '', state: 'needs_kit' ) if taskuser
        kit.save!
      end
    end
  end

  def set_needs_kit(kits)
    kits.each do |kit|
      if kit.state == 'assigned'
        taskuser = TaskUser.kit_taskuser(kit.uid).first
        taskuser.update( kit_oid: '', state: 'needs_kit' ) if taskuser
        kit.state = 'unassigned'
        kit.save!
      end
    end
  end

end
