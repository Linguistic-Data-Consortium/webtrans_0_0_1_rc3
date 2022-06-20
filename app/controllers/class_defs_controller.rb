class ClassDefsController < ApplicationController

  before_action :authenticate
  before_action :lead_annotator_user, except: [ :index2 ]
  before_action :lead_annotator_user_kit_user, only: [ :index2 ]
  before_action :admin_user, :only => [:destroy, :set_lock]


  include ClassDefsHelper
  include NodesHelper

  rescue_from StyleConnectionError, with: :standard_rescue

  def editclassdef
    if params[:kit_uid]
      kit = Kit.find_by_uid(params[:kit_uid])
      class_def = kit.tree.class_def
      nc = NodeClass.where(name: "#{class_def.name}:#{kit.uid}", class_def_id: class_def.id).first_or_create
      ok = (not nc.nil?)
      nc.constraints['edit'] ||= {}
      nc.constraints['edit']['inverted_grammar'] ||= class_def.inverted_grammar
      if params[:save]
        nc.destroy
        ok = true
      end
    end
    respond_to do |format|
      format.json do
        render json: { ok: ok }
      end
    end
  end

  # hack until better permissions can be set up
  def index2
    respond_to do |format|
      format.json do
        if params[:kit_uid]
          tree = Kit.find_by_uid(params[:kit_uid]).tree
          class_def = params[:editor] ? ClassDef.find(tree.class_def_id) : tree.class_def
        else
          class_def = ClassDef.find(params[:class_def_id])
        end
        h = {}
        ncs = {}
        h['node_classes'] = ncs
        g = class_def.inverted_grammar
        class_def.node_classes.includes(:parent).each do |nc|
          ncs[nc.id] = {}
          ncs[nc.id]['name'] = nc.name
          ncs[nc.id]['value'] = nc.value
          # raise StyleConnectionError, "missing style? node_type.id: #{nc.id}, node_type.name: #{nc.name}" if nc.style_id.nil?
          # ncs[nc.id]['tag'] = nc.style.tag
          ncs[nc.id]['types'] = nc.types
          # ncs[nc.id]['style'] = nc.style
          ncs[nc.id]['c'] = nc.constraints
          ncs[nc.id]['children'] = nc.children
          ncs[nc.id]['g'] = g[nc.id]
        end
        render json: h
      end
    end
  end

  #shows a paginated listing of all class defs, ordered alphabetically by name
  def index
    respond_to do |format|
      format.html do
        if params[:fetch] == 'webann'
          path = "/class_defs_index4.json?class_def_id=#{params[:id]}"
          @h = lui_http2(path)
          id = get_toolspppp @h
          redirect_to "/class_defs/#{id}/edit"
        else
          path = "/class_defs_index3"
          @h = JSON.parse(lui_http('webann.ldc.upenn.edu').get(path).body)
        end
      end
      format.json do
        render json: (
          if admin?
            ClassDef.sorted.all.map(&:attributes)
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  #shows the paths for all the node_classes within the namespace tree
  def show
    @class_def = ClassDef.find params[:id]
    respond_to do |format|
      format.html do
        @paths = []
        paths NodeClass.find_by_name("#{@class_def.name}:Root"), nil, @paths
      end
      format.json do
        node_classes = @class_def.node_classes.includes(:parent, :style)
        parents = node_classes.map { |x| x.parent }.uniq
        styles = node_classes.map { |x| x.style }.uniq
        render :json => (node_classes + parents + styles)
      end
      format.text do
        render :text => @class_def[:constraints]['conditionals'].to_json
      end
    end
  end

  #creates a new namespace with the specified name, along with its Root node
  def create
    @class_def = ClassDef.new params[:class_def].merge({bootstrap_mode: true}).permit(:name, :bootstrap_mode)
    root_class = NodeClass.new(:name => "#{@class_def.name}:Root", :parent_id => NodeClassTest.find_by_name('Root').id, :children => "")
    if @class_def.save
      if root_class.save
        @class_def.node_classes << root_class
        style = Style.new(:name => "#{@class_def.name}:Root_style")
        style.save!
        root_class.style = style
        root_class.save!
        @class_def.styles << style
        flash[:success] = "Successfully created the #{@class_def.name} namespace"
        redirect_to edit_class_def_path(@class_def)
      else
        flash[:error] = "Failed to create Root for #{@class_def.name}"
        redirect_to edit_class_def_path(@class_def)
      end
    else
      flash[:error] = @class_def.errors.full_messages.join(", ")
      redirect_back
    end
  end

  #releases the editing lock on a namespace from the current user
  def release
    @class_def = ClassDef.find params[:id]
    Lock.release 'namespace', @class_def.id, @current_user.id
    redirect_to class_defs_path
  end

  #provides a full screen preview of the namespace
  def preview
    @class_def = ClassDef.find params[:id]
    @title = "Preview for #{@class_def.name}"
    setup_tree
  end

  #clones an existing namespace into a new namespace of a specified name, creates all the necessary node_classes and styles
  def clone
    class_def = ClassDef.find params[:id]
    name = params[:name]
    @class_def = ClassDef.create( name: name, bootstrap: true )
    ActiveRecord::Base.transaction do
      if @class_def
        #cycle through the node classes and create each one and its style
        class_def.node_classes.each do |node_class|
          nc = NodeClass.new
          nc.name = "#{name}:#{node_class.name_without_prefix}"
          # the following line isn't totally safe
          nc.children = node_class.children.gsub(class_def.name, name) if node_class.children
          nc.class_def_id = @class_def.id
          %w[ parent_id value lazy ].each { |att| nc.send "#{att}=", node_class.send(att) }
          style = node_class.style
          s = Style.new
          s.name = "#{name}:#{style.name_without_prefix}"
          s.class_def_id = @class_def.id
          %w[ css horizontal hide classes tag reverse inline ].each do |att|
            s.send "#{att}=", style.send(att)
          end

          if s.save
            nc.style_id = s.id
            if nc.save
              #same code as edit from here
              @node_class = NodeClass.new#used for the add widget dialog form
              begin
                Lock.grab('namespace', @class_def.id, @current_user.id)
              rescue Lock::LockError => e
                redirect_to preview_class_def_path(@class_def), :flash => {:info => e.to_s}
                return
              end
            else
              flash[:error] = nc.errors.full_messages.join(", ")
              redirect_back
            end
          else
            flash[:error] = s.errors.full_messages.join(", ")
            redirect_back
          end
        end
      else
        flash[:error] = @class_def.errors.full_messages.join(", ")
        redirect_back
      end
    end
    @title = "Edit #{@class_def.name}"

    set_node_classes_and_names

    setup_tree

    flash[:success] = "Successfully cloned #{class_def.name} into #{name}"
    redirect_to edit_class_def_path(@class_def)
  end
  def edit
    @class_def = ClassDef.find params[:id]
    # @kit_types = KitTypes::KitType.all
    # create_labels
    @empty_node_class = NodeClass.new#used for the add widget dialog form
    set_parent_names
    @ok = @class_def.locked_by == @current_user.id || ClassDef.where(id: @class_def.id, locked_by: nil).update_all(locked_by: @current_user.id) == 1
    if @ok
    else
    end
  end

  def css
    @class_def = ClassDef.find params[:id]
    render plain: @class_def.css, content_type: 'text/css'
  end

  def edit_css
    @class_def = ClassDef.find params[:id]
  end

  def update_css
    @class_def = ClassDef.find params[:id]
    @class_def.css = params[:css]
    @class_def.save
    redirect_to edit_css_class_def_path
  end

  #read only tree viewer
  def tree_viewer
    @class_def = ClassDef.find params[:id]
    @node_class = NodeClass.new#used for the add widget dialog form
    begin
      Lock.grab('namespace', @class_def.id, @current_user.id)
    rescue Lock::LockError => e
      redirect_to preview_class_def_path(@class_def), :flash => {:info => e.to_s}
      return
    end
    @title = "Edit #{@class_def.name} - read only tree viewer"

    set_node_classes_and_names

    setup_tree

    @tree = create_tree_hash NodeClass.find_by_name("#{@class_def.name}:Root")
  end

  #this function locks a namespace when it is going live, also unlocks when annotation is complete
  def set_lock
    @class_def = ClassDef.find params[:id]
    @class_def.locked = params[:state]
    @class_def.save
    redirect_back
  end

  #this function increments the version of the namespace by 1
  def increment_version
    @class_def = ClassDef.find params[:id]
    @class_def.version += 1
    @class_def.save

    respond_to do |format|
      format.js do
        render :json => {:type => "success", :message => "#{@class_def.name} successfully incremented to version: #{@class_def.version}"}
      end
    end
  end

  #this action renames a class def, and all of its component node classes and styles along with it
  def update
    class_def = ClassDef.find params[:id]


    if params[:disable]
      params[:disable] == 'true' ? class_def.disable_constraints = true : class_def.disable_constraints = false
      class_def.save
      render :json => {:type => "success", :message => "successfully toggled constraints #{class_def.name}"}
      return
    end

    # this block parses the values given in the conditional modal to create parallel constraints using the values from each field with a given index
    if params[:conditional]
      class_def[:constraints] ||= {}
      class_def[:constraints]['conditionals'] ||= []
      map = {}
      cond_size = class_def[:constraints]['conditionals'].size
      cond_size == 0 ? class_def[:constraints]['conditionals'] << map : class_def[:constraints]['conditionals'][cond_size] = map
      map['widget'] = params[:widget].gsub(/\s+/, "").split(',')
      map['condition'] = params[:condition].gsub(/\s+/, "").split(',')
      map['value'] = params[:value].gsub(/\s+/, "").split(',')
      map['message'] = params[:message]
      if map['widget'].size == map['condition'].size && map['widget'].size == map['value'].size
        class_def.save!
        render :text => class_def[:constraints]['conditionals'].to_json
      else
        render :json => {:type => "failure", :message => "Wrong number of arguments"}
      end
      return
    end

    if params[:class_def] and params[:class_def][:kit_type_id]
      @kit = Kit.find_by_uid class_def.global
      @kit.kit_type_id = params[:class_def][:kit_type_id].to_i
      @kit.save
      respond_to do |format|
        format.js do
          render :json => {:type => "success", :message => "successfully changed javascript for #{class_def.name}" }
        end
      end
      return
    end

    ActiveRecord::Base.transaction do
      new_name = params[:new_name]

      original_name = class_def.name

      class_def.name = new_name

      if class_def.valid?
        class_def.node_classes.each do |nc|
          nc.name = nc.name.sub original_name, new_name
          nc.children = nc.children.gsub original_name, new_name if nc.children
          nc.save
        end

        class_def.styles.each do |s|
          s.name = s.name.sub original_name, new_name
          s.save
        end

        class_def.node_classes.each do |nc|
          nc.name = nc.name.sub original_name, new_name
          nc.children = nc.children.gsub original_name, new_name if nc.children
          nc.save
        end

        class_def.styles.each do |s|
          s.name = s.name.sub original_name, new_name
          s.save
        end

        class_def.global = nil
        class_def.save
        flash[:success] = "Successfully updated name to #{new_name}"
      else
        flash[:error] = class_def.errors.full_messages.join(", ")
      end
    end

    redirect_back
  end

  #this is the action that would delete an entire namespace, currently it is not implemented
  def destroy
    redirect_back
  end

  #this action updates the bootstrap mode attribute of a class def
  def update_bootstrap_mode
    class_def = ClassDef.find params[:id]
    class_def.bootstrap_mode = params[:class_def][:bootstrap_mode]
    class_def.save!
    redirect_back
  end

  def tables
    cd = ClassDef.find params[:id]
    title = 'blah'
    rows = []
    query = 'select * from kits limit 10'
    query = "
    SELECT
       *
    FROM
       pg_catalog.pg_tables
    WHERE
       schemaname != 'pg_catalog'
    AND schemaname != 'information_schema'"
    query  << ';'
    # query << "and tablename like '#{cd.name}%';"
    # query << "and tablename like 'a%';"
    @fields = %w[ tablename ]
    $sequel_rails.fetch(query).each do |row|
      rows << @fields.map { |x| row[x.to_sym] }
    end
    header = @fields.map(&:to_s)
    @table = {
      title: title,
      header: header,
      rows: rows
    }
    if cd.views_created
      render json: @table
    else
      render json: { message: 'no tables' }
    end
  end

  def create_tables
    cd = ClassDef.find params[:id]
    if cd.views_created
      cd.drop_tables
      render json: { message: 'tables exist' }
    else
      cd.create_tables
      render json: { message: 'creating' }
    end
  end
  
  private

  def standard_rescue(e)
    redirect_to class_def_path(@class_def), flash: { error: e.to_s }
  end

    #helper method to get the path of a node
    def paths(node, path, a)
      type = node.parent_name
      a << {:path => path, :type => type} if path

      if ['List', 'EmbeddedList'].include? type
        paths(NodeClass.find_by_name(node.children[node.children.index(".")+1..-1]), "#{path}.#{node.children[0..node.children.index(".")-1]}", a)
      else
        if node.children
          node.children.split(',').each do |child|
            child_name = child[0..child.index(".")-1]
            new_path = path.nil? ? child_name : "#{path}.#{child_name}"
            paths(NodeClass.find_by_name(child[child.index(".")+1..-1]), new_path, a)
          end
        end
      end
    end

  def create_labels
    @labels = {}
    @ncs = {}
    @class_def.node_classes.where(parent_id:7).each do |nc|
      @labels[nc.name.split(':')[1] ] = nc.value['label']
      @ncs[nc.name.split(':')[1] ] = nc
    end
  end

end
