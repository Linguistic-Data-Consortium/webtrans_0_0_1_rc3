class NodeClassesController < ApplicationController

  before_action :authenticate
  before_action :lead_annotator_user

  include ClassDefsHelper
  include NodesHelper

  def autocomplete
    @node_classes = NodeClass.all.order(:name).where("name LIKE ?", "%#{params[:term]}%").map(&:name).to_json
    respond_to do |format|
      format.json { render json: @node_classes }
    end
  end

  def index
    @title = "All node classes"
    respond_to do |format|
      format.html
      format.json {
        if params[:json_format] == 'datatable'
          render json: NodeClassesDatatable.new(view_context)
        else
          render json: NodeClass.all
        end
      }
    end
  end

  def show
    @node_class = NodeClass.find params[:id]
    @title = @node_class.name
    respond_to do |format|
      format.html
      format.json { render json: @node_class }
    end
  end

  def edit
    nc = NodeClass.find params[:id]
    respond_to do |format|
      format.html do
        html = render_to_string(:partial => "editt", :locals => { :nc => nc})
        render json: { html: html }
      end
    end
  end

  #adds a new nodeclass to the namespace
  def create
    @response = {}
    #don't continue if name is empty
    if params[:node_class][:name].empty?
      @response[:type] = "error"
      @response[:msg] = "Name cannot be empty"
      return
    end

    @class_def = ClassDef.find params[:class_def_id]
    set_node_classes_and_names2
    @nc = NodeClass.new
    stype = params[:node_class][:supertype]
    stype = 'Leaf' if stype == 'Basic'
    parent = NodeClass.find_by_name stype
    @nc.parent_id = parent.id
    @nc.children = ""#prevents nil check errors down the line
    @nc.value = {}

    #special initialization handling for types
    if choicelist_supertypes.include?(parent.name)
      @nc.children = nil
      @nc.value = {'labels' => [], 'values' => []}
      @nc.value['template'] = params[:node_class][:template] if params[:node_class][:template]
    end
    @nc.value = {'headers' => []} if parent.name == "Table"

    @nc.name = "#{@class_def.name}:#{params[:node_class][:name]}"

    #don't continue if the name is restricted
    if has_restricted_name(@nc.name, @class_def.name, "Add")
      return
    end

    if @nc.save
      @class_def.node_classes << @nc
      @response[:type] = "success"
      @response[:msg] = "Successfully added #{@nc.name_without_prefix}"

      # @class_def.node_classes << @nc
      @response[:node_class] = {:name => @nc.name_without_prefix, :id => @nc.id }
#        :html => render_to_string(:partial => "node_classes/edit", :locals => { :nc => @nc})}
      if @nc.parent.name == 'List'
        @nc2 = NodeClass.new
        @nc2.parent_id = NodeClass.find_by_name('Node').id
        @nc2.children = ""#prevents nil check errors down the line
        @nc2.value = {}
        @nc2.name = "#{@nc.name}Item"
        @class_def.node_classes << @nc2
        @nc.children = "#{@nc2.name.split(':').last}.#{@nc2.name}"
        @nc.save
      end

    else
      @response[:type] = "error"
      @response[:msg] = @nc.errors.full_messages.join(", ")
    end

    respond_to do |format|
      format.html do
        redirect_back(fallback_location: root_path)
      end
      format.json do
        render :json => @response
      end
    end
  end

  #saves a node_class within the namespace, and updates the tree accordingly (if necessary)
  def update

    return if params[:abort]

    edit_id = params[:which]

    @node_class = NodeClass.find params[:id]
    @class_def = @node_class.class_def

#     if params[:deletec].to_i == 1
#       @node_class.constraints ||= {}
#       if params[:map]
#         @node_class.constraints['maps'] = []
#         @node_class.constraints['maps'].each {|x| a[0].constraints['maps'].delete(x)}
#         @node_class.constraints.delete('maps') if @node_class.constraints['maps'].empty?
#       end
#       if params[:hide]
#         @node_class.constraints['patterns'] ||= []
#         @node_class.constraints['patterns'].delete_at(edit_id.to_i) if !edit_id.blank?
#       end
#       if params[:disable]
#         @node_class.constraints['patterns'] ||= []
#         @node_class.constraints['patterns'].delete_at(edit_id.to_i) if !edit_id.blank?
#       end
#       if params[:container]
#         @node_class.constraints['containers'] ||= []
#         @node_class.constraints['containers'].delete_at(edit_id.to_i) if !edit_id.blank?
#       end
#       if params[:add] || params[:delete] || params[:hide_button]
#         @node_class.constraints['messages'] ||= []
#         @node_class.constraints['messages'].delete_at(edit_id.to_i) if !edit_id.blank?
#         @node_class.constraints.delete('messages') if @node_class.constraints['messages'].empty?
#       end
#       if params[:label]
#         @node_class.constraints['labels'] ||= []
#         @node_class.constraints['labels'].delete_at(edit_id.to_i) if !edit_id.blank?
#       end
#       if params[:list]
#         @node_class.constraints['lists'] ||= []
#         @node_class.constraints['lists'].delete_at(edit_id.to_i) if !edit_id.blank?
#       end
#       if params[:attach]
#         @node_class.constraints['attach'] ||= []
#         @node_class.constraints['attach'].delete_at(edit_id.to_i) if !edit_id.blank?
#       end
#       @node_class.save!
#       render :json => @node_class
#       return
#     end

#     if params[:map] and params[:target]
#       @node_class.constraints ||= {}
#       @node_class.constraints['maps'] = []
#       map = {}
#       edit_id.blank? ? @node_class.constraints['maps'] << map : @node_class.constraints['maps'][edit_id.to_i] = map
#       map['root'] = params[:root]
#       map['target'] = params[:target]
#       map['map'] = {}
#       map = map['map']
#       params[:map].split.each do |v|
#         if params[v]
#           map[v] = params[v]
#         end
#       end
#       @node_class.save!
#       render :json => @node_class
#       return
#     end

#     if params[:hide] and params[:target]
#       @node_class.constraints ||= {}
#       @node_class.constraints['patterns'] ||= []
# #       @node_class.constraints['patterns'].each do |p|
# #         if p['node_class'] == "#{@class_def.name}:#{params[:target]}"
# #           render :json => @node_class
# #           return
# #         end
# #       end
#       if params[:hide] == 'show'
#         task_ids = (params[:task_ids].split).map { |x| x.to_i }
#         @node_class.constraints['patterns'].each { |x| task_ids.each { |y| (x['hide']['pattern']['task_ids'].delete(y) if x['hide']['pattern']['task_ids']) if x['hide']} }
#         @node_class.constraints['patterns'].each { |x| ((@node_class.constraints['patterns'].delete(x) if x['hide']['pattern']['task_ids'].empty?) if x['hide']['pattern']['task_ids']) if x['hide'] }
#         @node_class.save!
#         render :json => @node_class
#         return
#       end
#       map = {}
#       edit_id.blank? ? @node_class.constraints['patterns'] << map : @node_class.constraints['patterns'][edit_id.to_i] = map
#       if params[:target] == 'self'
#         map['node_class'] = @node_class.name
#         task_ids = (params[:task_ids].split).map { |x| x.to_i }
#         pattern = {}
#         if task_ids.length > 0
#           pattern = { 'task_ids' => task_ids }
#         else
#           pattern = { 'task_ids' => 'all' }
#         end
#         map['hide'] = {
#           'node_class' => @node_class.name,
#           'pattern' => pattern
#         }
#       else
#         map['root_selector'] = "." + params[:root]
#         map['node_class'] = "#{@class_def.name}:#{params[:target]}"
#         values = (params[:hide].split).map { |x| x if params[x] }.compact.join(' ')
#         map['hide'] = {
#           'node_class' => @node_class.name,
#           'pattern' => values
#         }
#       end
#       @node_class.save!
#       render :json => @node_class
#       return
#     end

#     if params[:disable] and params[:target]
#       @node_class.constraints ||= {}
#       @node_class.constraints['patterns'] ||= []
#       map = {}
#       edit_id.blank? ? @node_class.constraints['patterns'] << map : @node_class.constraints['patterns'][edit_id.to_i] = map
#       map['root_selector'] = "." + params[:root]
#       map['node_class'] = "#{@class_def.name}:#{params[:target]}"
#       values = (params[:disable].split).map { |x| x if params[x] }.compact.join(' ')
#       map['disable'] = {
#         'node_class' => @node_class.name,
#         'pattern' => values
#       }
#       @node_class.save!
#       render :json => @node_class
#       return
#     end



#     if params[:hide_button]
#       @node_class.constraints ||= {}
#       @node_class.constraints['messages'] = []
#       map = {}
#       edit_id.blank? ? @node_class.constraints['messages'] << map : @node_class.constraints['messages'][edit_id.to_i] = map
#       if params[:target] =~ /\.|\#/
#         map['target'] = params[:target]
#       else
#         map['target'] = params[:target].split.map { |x| '.' + x }.join(',')
#       end
#       map['hide_button'] = true
#       @node_class.save!
#       render :json => @node_class
#       return
#     end

#     if params[:label]
#       @node_class.constraints ||= {}
#       @node_class.constraints['labels'] ||= []
#       map = {}
#       edit_id.blank? ? @node_class.constraints['labels'] << map : @node_class.constraints['labels'][edit_id.to_i] = map
#       map['target'] = params[:target].split
#       map['small'] = params[:small] ? 'small' : 'true'
#       map['where'] = params[:where]
#       @node_class.save!
#       render :json => @node_class
#       return
#     end


#     if params[:list]
#       @node_class.constraints ||= {}
#       @node_class.constraints['lists'] ||= []
#       map = {}
#       edit_id.blank? ? @node_class.constraints['lists'] << map : @node_class.constraints['lists'][edit_id.to_i] = map
#       map['highlight'] = params[:target]
#       if params[:hover]
#         map['hover'] = "1"
#       else
#         map['hover'] = "0"
#       end
#       @node_class.save!
#       render :json => @node_class
#       return
#     end

#     if params[:container]
#       @node_class.constraints ||= {}
#       @node_class.constraints['containers'] ||= []
#       map = {}
#       edit_id.blank? ? @node_class.constraints['containers'] << map : @node_class.constraints['containers'][edit_id.to_i] = map
#       map['root'] = params[:root].split
#       if params[:target] =~ /\.|\#/
#         map['target'] = params[:target]
#       else
#         map['target'] = params[:target].split.map { |x| '.' + x }.join(',')
#       end
#       @node_class.save!
#       render :json => @node_class
#       return
#     end

#     if params[:tag]
#       respond_to do |format|
#         format.html do
#           style = @node_class.style
#           raise 'bad text for label' unless params[:text] =~ /^[-\w.?! \t]*\Z/
#           raise 'bad html tag' unless params[:tag] =~ /^\w*\Z/
#           @node_class.update(value: { 'label' => params[:text] }) if @node_class.value['label'] != params[:text]
#           style.update( tag: params[:tag] ) if style.tag != params[:tag]
#           class_def_edit_helper
#           redirect_to edit_class_def_path(@class_def)
#           return
#         end
#       end
#     end

    # @node_class.lazy = params[:lazy] == 'lazy'

    # @styles = @class_def.styles
    # if params[:node_class][:name].empty?
    #   @type = "error"
    #   @msg = "Name cannot be empty"
    #   puts @msg
    #   return
    # end

#     #blocks any save actions which could result in nil errors during annotation, should anybody make changes
    if @class_def.locked
      @type = "error"
      @msg = "#{@class_def.name} is currently locked and not accepting any changes, contact an admin if this should not be so."
      puts @msg
      return
    end

    original_name = "#{@node_class.name_without_prefix}"
    parent_name = @node_class.parent_name

#     #children attribute used only by non-leaf nodes
    node_supertypes.include?(parent_name) ? children = child_string_from_params(params, parent_name) : children = nil

#     #setting the value hash for leaf node types
    all_values_alphanumeric = true
    value = {}
    if params[:child_textt]
      value['extra'] ||= {}
      value['extra']['label'] = params[:child_textt]
    end
    # value['label'] = params[:node_class][:label]
    value['label'] = params[:child_text] if ["Label", "EntryLabel", "Entry", "Ref"].include? parent_name
    # value['template'] = params[:node_class][:template] if params[:node_class][:template]
    value['label'], value['message'] = params[:child_text], params[:child_action] if parent_name == "Button"
    # value['waveform'] = true if params[:waveform] == 'waveform'
    # value['document'] = true if params[:document] == 'document'
    # value['timestamps'] = true if params[:timestamps] == 'timestamps'
    # value['level'] = params[:level_text] if params[:level_text]
    if choicelist_supertypes.include?(parent_name) or parent_name == 'Leaf'
      value['labels'], value['values'] = Array.new, Array.new
      if params[:child_choice_values_labels]
        params[:child_choice_values_labels].split(/[\r\n]+/).each do |x|
          x =~ /^\s*(\S+)\s+(.+)/
          val, lab = $1, $2
          value['values'] << val
          value['labels'] << lab
      # if params[:child_choice_value] && params[:child_choice_label]
      #   params[:child_choice_value].each_with_index do |val, i|
      #     value['labels'][i] = params[:child_choice_label][i]
      #     #the values can only be alphanumeric strings
      #     value['values'][i] = "#{val}"
      #     if val.length == 0
      #       value['values'][i] = nil
      #       value['labels'][i] = nil
      #     end
          if !"#{val}".gsub!(/[^0-9a-z ]/i, '').nil?
            @type = "error"
            @msg = "#{val} is not an alphanumeric string"
            all_values_alphanumeric = false
            puts @msg
            return
          end
        end
      end
      value['values'].compact!
      value['labels'].compact!
      children = value['values'].join ","#temporarily set this so that we can validate the values with the same function as before
      puts 'childre'
      puts children
    end

#     #setting the value hash for tables
    if parent_name == "Table"
      value = {'headers' => Array.new}
      if params[:child_header_label] && params[:child_header_sort]
        params[:child_header_label].each_with_index do |val, i|
          value['headers'] << {'label' => val, 'sort' => params[:child_header_sort][i]}
        end
      end
    end

#     #don't continue if childnames are not all unique
    puts children
    if !childnames_unique(children)
      puts 'not unique'
      return
    end

    new_name = "#{@class_def.name}:#{params[:node_class][:name]}"

#     #don't continue if the name is being updated to a restricted value
    if has_restricted_name(new_name, @class_def.name, "Save")
      puts 'has restricted'
      return
    end

    # @node_class.name = new_name unless original_name == "Root"
    # # @node_class.style_id = params[:node_class][:style_id]
    # children = nil if choicelist_supertypes.include? parent_name#restore this value to nil for the choicelists
    # children_have_changed = (@node_class.children != children)#used for the determination of whether to reset the tree
    # @node_class.children = children
    @node_class.value = value
    puts 2
    # set_node_classes_and_names
    # @node_classes << @node_class

    #note this will check ALL node classes in the namespace for this, regardless of whether they are actually part of the tree
    @names = @class_def.node_class_names
#     @node_classes.each do |node_class|
# #       if !child_exists(node_class)
# #         puts "not child exists: #{node_class.name}"
# #         return
# #       end
#     puts 4
# #       #don't allow the name to be changed when the node class is a child of another
#       if original_name != @node_class.name_without_prefix && node_class.children
#         node_class.children.split(',').each do |child|
#           type = child[child.index(":")+1..-1]
#           if type == original_name
#             @type = "error"
#             @msg = "#{original_name} exists as a child of #{node_class.name_without_prefix}, cannot change name"
#             puts 'error'
#             return
#           end
#         end
#       end
#     end
#     puts 1
#     @types = Hash.new#k - the type, v - boolean whether it has been found in the tree structure already
#     if node_supertypes.include? @node_class.parent_name
#       @node_class.children.split(',').each do |child|
#         @types[child[child.index(":")+1..-1]] = false
#       end
#     end
#     puts 5
#     infinite_loop = infinite_loop_exists NodeClass.find_by_name("#{@class_def.name}:Root")
#     logger.debug "infinite loop found: #{infinite_loop}"

#     if !infinite_loop#if there is no infinite loop, we are ok to save
#       if @node_class.save#all validations have passed, go ahead and try to make the actual save
#         reset_root if children_have_changed
#         setup_tree

#         #create the objects for the json return
#         # workspace_html = render_to_string :partial => 'annotate/node', :locals => { :p => @kit.tree.tree }
#         obj = @kit.to_hash(false, 'deep').to_json.html_safe

#         @type = "success"
#         @msg = "Successfully updated #{@node_class.name_without_prefix}"
#       else
#         @type = "error"
#         @msg = @node_class.errors.full_messages.join(", ")
#         @node_class = NodeClass.find params[:id]

#         #create the objects for the json return
#         workspace_html = nil
#         obj = nil
#       end
#     end
#     puts 6
#     controls_html = render_to_string :partial => "/node_classes/edit", :locals => { :nc => @node_class}

    nc = params[:node_class]
    if nc

      %w[ classes table_columns tab_titles columns ].each do |k|
        if nc[k]
          if nc[k] == ''
            @node_class.constraints.delete k
          else
            @node_class.constraints[k] = nc[k]
          end
        end
      end

      %w[ auto_add ].each do |k|
        if nc[k]
          @node_class.constraints[k] = nc[k].to_i
          @node_class.constraints.delete k if nc[k].to_i == 0
        end
      end

      %w[ add_to_top reverse_order ncrnt ].each do |k|
        if nc[k]
          @node_class.constraints[k] = true
        else
          @node_class.constraints.delete k
        end
      end

      wrap = []
      nc.each do |k, v|
        if k =~ /wrap-(\d+)-(\d)/
          ki, kj = $1.to_i, $2.to_i
          wrap[ki] ||= []
          wrap[ki][kj] = v
        end
      end
      wrap.select! { |x,y| x =~ /\S/ and y =~ /\S/ }
      @node_class.constraints['wrap'] = wrap
      @node_class.constraints.delete 'wrap' if wrap.length == 0

      control = []
      nc.each do |k, v|
        if k =~ /control-(\d+)-(\d)/
          ki, kj = $1.to_i, $2.to_i
          control[ki] ||= []
          control[ki][kj] = v
        end
      end
      control.select! { |x| x.count { |x| x =~ /\S/ } == 3 }
      if nc['control-which'] and nc['control-which'].length > 0
        @node_class.constraints['control'] = { 'which' => nc['control-which'] }
        @node_class.constraints['control']['patterns'] = control
        @node_class.constraints.delete 'control' if control.length == 0
      else
        @node_class.constraints.delete 'control'
      end

      ns = @node_class.class_def.name
      if params[:node_class][:children]
        @node_class.children = params[:node_class][:children].split(' ').map { |x| "#{x}.#{ns}:#{x}" }.join(',')
      end

      @node_class.constraints['messages'] ||= []
      @node_class.constraints['messages'] = @node_class.constraints['messages'].select { |x|
        (not x.has_key? 'add') and
        (not x.has_key? 'delete')
      }
      @node_class.constraints['attach'] ||= []

      if nc[:add]
      # if params[:add]
        # edit_id.blank? ? @node_class.constraints['messages'] << map : @node_class.constraints['messages'][edit_id.to_i] = map
        # targetWidget = NodeClassTest.find_by_name("#{@class_def.name}:#{params[:target]}")
        targetWidget = NodeClass.find_by_name("#{@class_def.name}:#{nc[:add]}")
        if targetWidget && targetWidget.parent_name == "List"
          map = @node_class.constraints['messages'].select { |x| x['add'] }.first
          if map.nil?
            map = {}
            @node_class.constraints['messages'] << map
          end
          map['target'] = nc[:add]
          map['add'] = {}
        else
          # flash[:error] = "Target must be a list!"
        end
      end

      if nc[:delete]
        map = @node_class.constraints['messages'].select { |x| x['delete'] }.first
        if map.nil?
          map = {}
          @node_class.constraints['messages'] << map
        end
        map['delete'] = nc[:delete] == 'false' ? nil : nc[:delete]
        if params[:target]
          targetWidget = NodeClassTest.find_by_name("#{@class_def.name}:#{params[:target]}")
          if targetWidget && targetWidget.parent_name == "List"
            map['target'] = "#{@class_def.name}:#{params[:target]}"
            map['deletecurrent'] = 'true'
            @node_class.save!
            render :json => @node_class
          else
            flash[:error] = "Target must be a list!"
          end
          return
        end
      end

      if nc[:attach]
      # if params[:add]
        # edit_id.blank? ? @node_class.constraints['messages'] << map : @node_class.constraints['messages'][edit_id.to_i] = map
        # targetWidget = NodeClassTest.find_by_name("#{@class_def.name}:#{params[:target]}")
        map = @node_class.constraints['attach'].select { |x| x['where'] }.first
        if map.nil?
          map = {}
          @node_class.constraints['attach'] << map
        end
        map['target'] = nc[:attach].split
        map['where'] = nc[:where]
      end

      if params[:constraints_map]
        m = {}
        params[:constraints_map].split(/[\r\n]+/).each do |line|
          if line =~ /^\s*(\w+)\s*:(.+)/
            m[$1] = $2
          end
        end
        @node_class.constraints['maps'].first['map'] = m
      end

      @node_class.save!
    end

    respond_to do |format|
      format.json do
        render json: @node_class
        # render :json => {:id => @node_class.id, :type => @type, :message => @msg, :controls_html => controls_html,
        #   :workspace_html => workspace_html, :obj => obj, :name_without_prefix => @node_class.name_without_prefix}
      end
    end
  end

  #adds a new child to the list of children
  def add_child
    # @nc = NodeClass.find params[:id]
    # @class_def = @nc.class_def
    # @parent_name = @nc.parent_name
    # if params[:child]
    #   @child = params[:child]
    #   @parent_name = params[:parent]
    # else
    #   if ["Label", "EntryLabel", "Button"].include? @parent_name
    #     @child = ""
    #   elsif choicelist_supertypes.include? @parent_name
    #     @child = []
    #   else
    #     @child = "NewName.#{@class_def.name}:NewName"
    #   end
    # end

    # set_node_classes_and_names

    # child_html = render_to_string(:partial => "child", :locals => { :nc => @nc, :child => @child, :parent_name => @parent_name})

    # respond_to do |format|
    #   format.json do
    #     render :json => {:id => "#{@nc.id}", :child_html => child_html}
    #   end
    # end
  end

  def destroy
    # @node_class = NodeClass.find params[:id]
    # name = @node_class.name_without_prefix
    # @class_def = @node_class.class_def

    # if @class_def.locked
    #   @type = "error"
    #   @msg = "#{@class_def.name} is currently locked and not accepting any changes, contact an admin if this should not be so."
    # end

    # @class_def.node_classes.each do |node_class|
    #   #don't allow the name to be deleted when the node class is a child of another
    #   if name != node_class.name_without_prefix && node_class.children
    #     node_class.children.split(',').each do |child|
    #       type = child[child.index(":")+1..-1]
    #       if type == name
    #         @type = "error"
    #         @msg = "#{name} exists as a child of #{node_class.name_without_prefix}, cannot delete"
    #       end
    #     end
    #   end
    # end

    # #if we have not found an error above, delete the node class
    # if @type != "error"
    #   @node_class.destroy
    #   @type = "success"
    #   @msg = "Successfully removed #{name}"
    # end

    # respond_to do |format|
    #   format.json do
    #     render :json => {:id => @node_class.id, :type => @type, :message => @msg}
    #   end
    # end
  end

end
