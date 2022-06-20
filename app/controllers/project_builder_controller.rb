class ProjectBuilderController < ApplicationController
  before_action :authenticate
  before_action :set_task, :only => [:create_widget, :create_template]
  before_action :set_project, :only => [:create_widget, :create_template]
  before_action :project_manager_user, :only => [:new, :create, :destroy, :project]
  before_action :project_designer_user, :only => [:task, :data_set, :create_widget, :create_template, :choose_task, :choose_dataset]
  # before_action :task_admin_user, :only => [:choose_project, :choose_task, :choose_dataset, :create_template]

  require 'json'

  include ClassDefsHelper
  include NodesHelper
  include ClassDefStyleHelper

  def project
    @project = Project.new
    respond_to do |format|
      format.json do
        html = render_to_string(:partial => "project.html", :locals => { :project => @project})
        render json: { html: html }
      end
    end
  end

  def choose_project
    if current_user.portal_manager?
      @projects = Project.all
    else
      @projects = ProjectUser.where(user: current_user, admin: true).map { |x| x.project}
    end
    @project = Project.new
    respond_to do |format|
      format.json do
        html = render_to_string(:partial => "choose_project.html", :locals => { :project => @project, :projects => @projects})
        render json: { html: html }
      end
    end
  end

  def task
    @task = Task.new
    @project = Project.find(params["project_id"])
    @workflows = Workflow.all_newest_first
    @kit_types = KitType.all_newest_first
    respond_to do |format|
      format.html do
        html = render_to_string(:partial => "task")
        render json: { html: html }
      end
    end
  end

  def choose_task
    @tasks = Project.find(params['project_id']).tasks
    @task = Task.new
    respond_to do |format|
      format.html do
        html = render_to_string(:partial => "choose_task", :locals => { :task => @task, :tasks => @tasks})
        render json: { html: html }
      end
    end
  end

  def dataset
    @data_set = DataSet.new
    respond_to do |format|
      format.html do
        html = render_to_string(:partial => "dataset", :locals => { :data_set => @data_set})
        render json: { html: html }
      end
    end
  end

  def choose_dataset
    @data_sets = DataSet.all
    @data_set = DataSet.new
    @task = Task.find(params[:task_id])
    respond_to do |format|
      format.html do
        html = render_to_string(:partial => "choose_dataset", :locals => { :data_set => @data_set, :data_sets => @data_sets})
        render json: { html: html }
      end
    end
  end

  def tool
    respond_to do |format|
      format.html do
        html = render_to_string(:partial => "tool")
        render json: { html: html }
      end
    end
  end

  def template
    @task = Task.find(params[:task])
    @class_def = ClassDef.find(params[:class_def_id])
    m_d = @task.data_set.manifest.download
    manifest = JSON.parse(m_d)
    @manifest_columns = manifest["list"][0].keys
    respond_to do |format|
      format.json do
        html = render_to_string(:partial => "project_builder/templates/root.html")
        render json: { html: html }
      end
    end
  end

  def create_template
    puts params
    if check_required
      build_from_template
      redirect_to(root_path)
    else
      flash[:error] = "Missing required fields for template."
      redirect_to(new_project_builder_path)
    end
  end

  def widget
    @type = params[:widget_type]
    if params[:node_class]
      @node_class = NodeClass.find( params[:node_class_id] )
    else
      @node_class = NodeClass.new
    end
    @class_def = ClassDef.find params[:class_def_id]
    respond_to do |format|
      format.html do
        html = render_to_string(:partial => "widget")
        render json: { html: html }
      end
    end
  end

  def create_widget
    @class_def = ClassDef.find params[:class_def_id]
    set_node_classes_and_names2
    @node_class = NodeClass.new
    @type = params[:widget_type]
    case @type
    when 'Button'
      stype = 'Button'
    when 'Entry Field'
      stype = 'Leaf'
      @node_class.constraints = {"classes"=>"Entry"}
    when 'Dropdown Selector'
      stype = 'Leaf'
      @node_class.constraints = {"classes"=>"Menu"}
      labels = params[:node_class][:value][:options].split
      values = params[:node_class][:value][:options].downcase.split
      @node_class.value = {"labels" => labels, "values" => values}
    when 'Display Text'
      stype = 'Label'
    when 'Audio'
      stype = 'Audio'
      classes = []
      if params[:node_class][:value][:waveform] == 'waveform'
        classes.append('Wveform')
      end
      @node_class.constraints = {"classes"=> classes.join(' ')}
    end
    parent = NodeClass.find_by_name stype
    @node_class.parent_id = parent.id
    @node_class.children = "" #prevents nil check errors down the line
    @node_class.value ||= {}
    # because Rails doesn't allow to_h for params unless permitted
    params[:node_class][:value].each do |k,v|
      @node_class.value[k] = v unless v == ''
    end
    @node_class.name = "#{@class_def.name}:#{params[:node_class][:name].gsub(/\W+/, '').camelize}"
    if stype == 'Label' && !@node_class.name.match(/Label$/)
      @node_class.name = @node_class.name + 'Label'
    elsif stype == 'Button' && !@node_class.name.match(/Button$/)
      @node_class.name = @node_class.name + 'Button'
    end
    @node_class.constraints ||= {}
    if %w[Label].include?(stype)
      @node_class.constraints.merge!({"messages"=>[], "attach"=>[{"target"=>["DefaultListItem"], "where"=>"prepend"}]})
    elsif %w[Button].include?(stype)
      @node_class.constraints.merge!({"messages"=>[], "attach"=>[{"target"=>["DefaultListItem"], "where"=>"append"}]})
    end
    if @node_class.save
      if %w[Label].include?(stype)
        paired_label_widget = create_label_for_widget(@node_class)
        @class_def.node_classes << paired_label_widget
        paired_label_cname = paired_label_widget.name.split(':')[1] + '.' + paired_label_widget.name
      end
      @class_def.node_classes << @node_class
      list_item = NodeClass.where(:class_def => @class_def, :name => @class_def.name + ":DefaultListItem").first
      list_item_children = list_item.children.split(',')

      cname = @node_class.name.split(':')[1] + '.' + @node_class.name
      if !%w[Label Button].include?(stype)
        list_item_children << cname unless list_item_children.include?(cname)
      end
      list_item.children = list_item_children.join(',')
      list_item.save
      respond_to do |format|
        nc = @node_class.attributes
        nc['type'] = @type
        format.json { render json: { node_class: nc } }
      end

    else
      puts @node_class.errors.full_messages.join(", ")
    end
  end

  def new
    @body_class = "project_builder"
  end

  private

  def create_label_for_widget(widget_node_class)
    node_class = NodeClass.new
    type = 'Label'
    parent = NodeClass.find_by_name type
    node_class.parent_id = parent.id
    node_class.children = "" #prevents nil check errors down the line
    node_class.value = {}
    node_class.value['label'] = widget_node_class.value['label']
    node_class.name = "#{widget_node_class.name}" + type
    if widget_node_class == type
      node_class.name = node_class.name + type # labels will end in LabelLabel when the main widget is a label
      # really we should fix the app so we don't have to include Label in the names of Label widgets
    end
    node_class.constraints ||= {}
    node_class.constraints.merge!({ "messages"=>[], "attach"=>[{"target"=>[widget_node_class.name.split(':')[1]], "where"=>"before"}] })
    node_class.save!
    node_class
  end

  def check_required
    required_fields = [:media_type, :media_content, :prompt_id_field]
    required_fields.each do |x|
      if !params[:class_def].key?(x) || params[:class_def][x].blank?
        return false
      end
    end
    # conditionally required fields should be added here
    return true
  end

  def build_from_template
    @class_def = ClassDef.find params[:class_def][:id]
    @task = Task.find params[:task_id]
    set_node_classes_and_names2

    @list_item_node = NodeClass.where(:class_def => @class_def, :name => "#{@class_def.name}:DefaultListItem").first

    if params[:class_def][:language_selector] == 'yes'
      if params[:class_def][:limit_languages] == 'yes'
        add_widget(@class_def, {:type => 'Dropdown Selector', :value => {:label => 'Language'}, :name => 'Language', :languages => params[:class_def][:languages]})
      else
        add_widget(@class_def, {:type => 'LanguageAutocomplete', :value => {:label => 'Language'}, :name => 'LangAutocomplete'})
      end
    end

    add_widget(@class_def, {:type => 'Leaf', :name => 'Judgment'})

    add_widget(@class_def, {:type => 'Leaf', :name => 'PromptID', :value => {"prompt_id_field"=> params[:class_def][:prompt_id_field] }})

    if params[:class_def][:media_type] == 'audio'
      set_class_def_css(@class_def, 'audio')
      audio_widget_classes = []
      audio_widget_classes << 'Wveform'
      audio_widget_classes << 'play_pause_restart'
      audio_widget_classes << 'start_end_time'
      audio_widget_classes << 'show_time'
      add_widget(@class_def, {:type => 'Audio', :name => 'ListAudio', :classes => audio_widget_classes, :value => {"media_id_field"=> params[:class_def][:media_content]}})
      set_class_def_css(@class_def, 'audio')
      kt = @task.kit_type
      kt.meta = {"feature_files"=>"{\"audio_list\":\"audio_list\"}"}
      kt.save
    elsif params[:class_def][:media_type] == 'text'
      set_class_def_css(@class_def, 'text')
      add_widget(@class_def, {:type => 'Leaf', :name => 'ListText', :value => {"media_id_field"=> params[:class_def][:media_content], "media_type" => params[:class_def][:media_type] }})
      # add_widget(@class_def, {:type => 'Leaf', :name => 'TextResponse'})
      kt = @task.kit_type
      kt.meta = {"feature_files"=>"{\"text\":\"text\"}"}
      kt.save
    elsif %w(image video).include? params[:class_def][:media_type]
      set_class_def_css(@class_def, 'othermedia')
      add_widget(@class_def, {:type => 'Leaf', :name => 'ListMedia', :value => {"media_id_field"=> params[:class_def][:media_content], "media_type" => params[:class_def][:media_type] }})
      kt = @task.kit_type
      kt.meta = {"feature_files"=>"{\"media_list\":\"media_list\"}"}
      kt.save
    else # if "manifest text only" is selected
      set_class_def_css(@class_def, 'manifest_text')
    end

    if params[:class_def][:audio_response] == "yes"
      if params[:class_def][:level_meter] == "yes"
        add_widget(@class_def, {:type => 'Leaf', :name => 'AudioResponse', :classes => ["level_meter"]})
      else
        add_widget(@class_def, {:type => 'Leaf', :name => 'AudioResponse'})
      end
      if params[:class_def][:level_test] == "yes"
        kt = @task.kit_type
        kt.constraints = kt.constraints.merge({"level_test": "yes"})
        kt.save
      end
    end

    if params[:class_def][:input_primary] == "yes" and !params[:class_def][:input_source_primary].blank? and !params[:class_def][:input_source_primary_label].blank?
      add_widget(@class_def, {:type => 'Display Text', :value => {:label => params[:class_def][:input_source_primary_label], :input_source => params[:class_def][:input_source_primary]}, :name => 'PrimaryText'})
    end

    if params[:class_def][:input_secondary] == "yes" and !params[:class_def][:input_source_secondary].blank? and !params[:class_def][:input_source_secondary_label].blank?
      add_widget(@class_def, {:type => 'Display Text', :value => {:label => params[:class_def][:input_source_secondary_label], :input_source => params[:class_def][:input_source_secondary]}, :name => 'SecondaryText'})
    end

    if params[:class_def][:text_annotation] == 'yes' and !params[:class_def][:annotation_name].blank?
      add_widget(@class_def, {:type => 'Entry Field', :name => params[:class_def][:annotation_name], :value => {"label"=> params[:class_def][:annotation_label]}})
    end

    if params[:class_def][:multiple_choice] == "yes"
      buttons = []
      multiple_options = params[:class_def][:buttons].split(/\r?\n/)
      if multiple_options.size > 0
        value = {"labels" => [], "values" => []}
        multiple_options.each do |option|
          value["labels"].push option
          value["values"].push option.gsub(/\W+/, '')
        end
        add_widget(@class_def, {:type => 'Checkbox', :name => "ListCheckbox", :value => value, :classes => ["Checkbox"]})
      end
    else
      buttons = params[:class_def][:buttons].split(/\r?\n/)
    end

    if buttons.size == 0
      buttons = ["Submit"]
    end

    buttons.each do |button|
      add_widget(@class_def, {:type => 'Button', :name => button.gsub(/\W+/, ''), :value => {"label"=>button, "action"=>"annotation"}})
    end
    
    if params[:class_def][:skip] == 'yes'
      add_widget(@class_def, {:type => 'Button', :name => 'Skip', :value => {"label"=>"Skip", "action"=>"next"}, :classes => ["button-danger"]})
    end

    if params[:class_def][:report] == 'yes'
      add_widget(@class_def, {:type => 'Button', :name => 'Report', :value => {"label"=>"Report", "action"=>"report"}, :classes => ["button-danger"]})
    end

    if @buttons_to_wrap&.size > 0
      wrap_string = @buttons_to_wrap.map { |x| "." + x }.join(", ")
      @list_item_node.constraints.merge!({"wrap"=>[[wrap_string, "ButtonsWrapper", "append"]]})
      @list_item_node.save
    end

    if params[:class_def][:exercise_text] != ""
      add_widget(@class_def, {:type => 'Display Text', :value => {:label => params[:class_def][:exercise_text]}, :name => 'ExerciseText'})
    end

  end

  def add_widget(class_def, details)
    node_class = NodeClass.new
    type = details[:type]
    case type
    when 'Button'
      stype = 'Button'
    when 'Entry Field'
      stype = 'Leaf'
      node_class.constraints = {"classes"=>"Entry"}
    when 'Dropdown Selector'
      stype = 'Leaf'
      node_class.constraints = {"classes"=>"Menu"}
      labels = details[:languages].split
      values = details[:languages].downcase.split
      node_class.value = {"labels" => labels, "values" => values}
    when 'LanguageAutocomplete'
      stype = 'Leaf'
      node_class.constraints = {"classes"=>"LanguageAutocomplete"}
    when 'Display Text'
      stype = 'Label'
    when 'Audio'
      stype = 'Audio'
    when 'Leaf'
      stype = 'Leaf'
    when 'Checkbox'
      stype = 'Leaf'
    end

    if details.key?(:classes)
      if node_class.constraints.key?("classes")
        puts "adding to classes"
        node_class.constraints["classes"] = node_class.constraints["classes"] + details[:classes].join(' ')
      else
        node_class.constraints["classes"] = details[:classes].join(' ')
      end
    end

    parent = NodeClass.find_by_name stype
    node_class.parent_id = parent.id
    node_class.children = "" #prevents nil check errors down the line
    node_class.value ||= {}
    # because Rails doesn't allow to_h for params unless permitted

    # should explicitly list these options if possible
    if details[:value]
      details[:value].each do |k,v|
        node_class.value[k] = v unless v == ''
      end
    end

    node_class.name = "#{class_def.name}:#{details[:name].gsub(/\W+/, '').camelize}"
    if stype == 'Label' && !node_class.name.match(/Label$/)
      node_class.name = node_class.name + 'Label'
    elsif stype == 'Button' && !node_class.name.match(/Button$/)
      node_class.name = node_class.name + 'Button'
    end

    node_class.constraints ||= {}

    if details.key?(:attach)
      node_class.constraints.merge!(details[:attach]).merge!({"messages"=>[]})
    elsif %w[Label].include?(stype)
      node_class.constraints.merge!({"messages"=>[], "attach"=>[{"target"=>["DefaultListItem"], "where"=>"prepend"}]})
    elsif %w[Button].include?(stype)
      node_class.constraints.merge!({"messages"=>[], "attach"=>[{"target"=>["DefaultListItem"], "where"=>"append"}]})
      @buttons_to_wrap ||= []
      @buttons_to_wrap << node_class.name.split(":")[1]
    end

    if node_class.save

      class_def.node_classes << node_class

      list_item_children = @list_item_node.children.split(',')

      # not sure what's with this name construction
      cname = node_class.name.split(':')[1] + '.' + node_class.name

      if !%w[Label Button].include?(stype)
        list_item_children << cname unless list_item_children.include?(cname)
      end

      @list_item_node.children = list_item_children.join(',')
      @list_item_node.save
    end

  end

  def set_task
    @task = Task.find(params[:task_id])
  end

  def set_project
    @project = @task.project
  end

  def project_manager_user
    true
  end

  def project_designer_user
    true
  end

end
