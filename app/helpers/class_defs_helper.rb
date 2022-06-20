module ClassDefsHelper
  
  class FakeKit
    attr_accessor :read_only, :parent, :editor, :quality_control, :tree, :bootstrap_mode

    def to_hash
      h = {}
      h['tree'] = @tree.tree.to_client_hash unless @tree.nil?
      [ :read_only, :quality_control, :editor, :bootstrap_mode ].each do |sym|
        h[sym.to_s] = "#{ self.send sym }"
      end
      h
    end
  end
  
  def class_def_edit_helper
    @title = "Edit #{@class_def.name}"
    set_node_classes_and_names
    setup_tree  
    @styles = @class_def.styles.order(:name) # why is this duplicated?
  end
    
  def restricted_names(class_def_name, action)
    restricted_name_arr = Array.new
    ['Root', 'children', 'refdoc'].each do |rname|
      restricted_name_arr << "#{class_def_name}:#{rname}" unless action == 'Save' && rname == 'Root'
    end
    restricted_name_arr
  end
  
  #array of supertypes whose children contain a list of sub-nodes
  def node_supertypes
    {"Node" => '', "Root" => '', "List" => '', "EmbeddedList" => '', "Tabs" => '', 'TableList' => ''}
  end
  
  #array of supertypes whose children contain a list of choices for use in specific widgets
  def choicelist_supertypes
    { "Menu" => '', "MultiMenu" => '', "Radio" => '', "CheckboxGroup" => '', 'ChoiceLabel' => '', 'ButtonGroupRadio' => '' }
  end
  
  def labelbutton_types
    { "Label" => '', "EntryLabel" => '', "Button" => '', 'Entry' => '' }
  end
  
  def nonlist_node_supertypes
    {"Node" => '', "Root" => '', "Tabs" => ''}
  end
  
  def list_supertypes
    {'List' => '', 'EmbeddedList' => '', 'TableList' => ''}
  end
  

  #function that sets up the tree for rendering the workspace properly
  def setup_tree

    user_id, task_id = user_helper
    task = Task.find_by_name('namespaces') #if errors, replace this and following line
    task_id = task.id #with task_id = 4 for Alex, task_id = 227 for Jon and presumabley deployment
    task_user = TaskUser.where( user_id: user_id, task_id: task_id ).first
    if not @class_def.global or not Kit.find_by_uid(@class_def.global)
      task = Task.find_by_name('namespaces')
      task_id = task.id
      tree = new_root_editor user_id, task_id
      @kit = Kit.new
      raise 'user not in task' if task_user.nil? # what error type should be raised here?
      @kit.task_id = task_id
      @kit.kit_type_id = task.kit_type_id
      @kit.task_user_id = task_user.id
      # @kit.read_only = true
      @kit.parent = nil
      @kit.quality_control = false
      @kit.editor = true
      @kit.tree_id = tree.id
      @kit.state = 'assigned'
      @kit.source[:uid] = @kit.source[:id] = 'to_be' #NYT_ENG_20100216.0142'
      @kit.source[:type] = 'document'
      @kit.save!
      task_user.update( kit_oid: @kit.uid )
      @class_def.update(:global => @kit.uid)
      root = tree.tree
      tree.nodes.where( node_class_id: @class_def.node_classes.where(parent_id:3).pluck(:id) ).each do |node|
        if node.constraints['auto_add'].nil?
          node.children = []
          tree.add_new_node node, user_id, task_id
        end
      end
    else
      @kit = Kit.find_by_uid @class_def.global
      @kit.source[:uid] = @kit.source[:id] = 'to_be' #'NYT_ENG_20100216.0142'
      @kit.source[:type] = 'document'
      @kit.user_id = user_id
      @kit.task_user_id = task_user.id
      @kit.save!
    end

    if @kit.tree_id.nil?
      tree = new_root_editor user_id, task_id
      @kit.tree_id = tree.id
      @kit.save!
    end

    @kit.tree.update(version: 0) if @kit.tree.version.nil?

    # @kit.save!
    # @kit.tree.testt = true
    @kit.tree.elaborate_root user_id, task_id
    # @kit.tree = elaborate_root glob
    @kit.bootstrap_mode = @class_def.bootstrap_mode
    #raise @kit.tree.tree.children_nodes.to_s
    #@json = @kit.to_hash.to_json
  end

  #function that checks that all child names within a specially formated string of children are unique
  def childnames_unique(children_str)     
    parent_name = @node_class.parent_name
    if node_supertypes.include?(parent_name) || choicelist_supertypes.include?(parent_name)
      children = Hash.new
      children_str.split(",").each do |child|
        choicelist_supertypes.include?(parent_name)  ? name = child : name = child[0..child.index(".")-1]
        if !children.include? name
          children[name] = name
        else
          @type = "error"
          @msg = "Update failed, each child's name must be unique."
          puts children.keys.join(' ')
          return false
        end
      end
    end
    return true
  end
  
  #function that checks a name against a restricted list for saving node classes
  def has_restricted_name(name, class_def_name, action)
    list = restricted_names(class_def_name, action)
    list.each do |n|
      if name == n
        @type = "error"
        @msg = "#{action} failed, the widget name \"#{n[n.index(":")+1..-1]}\" is restricted."
        return true
      end
    end
    return false    
  end
  
  #function that checks whether the children for a given node_class exist in the namespace, if not returning the correct error msg
  def child_exists(node_class)
    if node_supertypes.include?(node_class.parent_name) && node_class.children
      node_class.children.split(",").each do |child|
        name = child[0..child.index(".")-1]
        type = child[child.index(":")+1..-1]
        if !@names.include?(type)
          @type = "error"
          @msg = "Cannot rebuild the tree, node_class #{node_class.name_without_prefix} has the child with name:#{name} and type:#{type} which does not exist."
          puts @msg
          return false
        end
      end
    end
    return true
  end
  
  #function that builds the children string from the input parameters
  def child_string_from_params(params, parent_name)
    array = Array.new
    if !params[:child_name].nil?
      params[:child_name].each_with_index do |name, index|
        name = name.gsub(' ', '_') if parent_name == "Tabs"#encoding the child names for tabs
        array << "#{name.gsub(/[.,:]/, "")}.#{@class_def.name}:#{params[:child_type][index].gsub(/[.,:]/, "")}"# [.,:] characters can all screw up our parsing, so just remove them
      end
    else
      array << ""
    end
    array.join(",")
  end
  
  #function that checks for the infinite loop scenario where a child points to a node above it in the tree
  def infinite_loop_exists(current_node)
    return false if @types.empty?#no need to check if children are empty, or this is a not in the node_supertype list
    
    #mark the child as being found in the tree, need to verify that the node class being saved also exists in the tree before this can be an infinite loop
    if @types.include? current_node.name_without_prefix
      @types[current_node.name_without_prefix] = true 
    end
    
    #gather the current children for tree traversal
    current_types = Array.new
    current_node.children = '' if current_node.children.nil?#handling the children = nil scenario
    current_node.children.split(',').each do |child|
      current_types << child[child.index(":")+1..-1]
    end
    
    if current_node.name == @node_class.name #if we've reached the saved node class
      found_match = false
      @types.each do |k,v|
        found_match = true if v#the node class being saved exists in the tree, and this child has been marked as existing above him in the tree 
        @type = "error"
        @msg = "Cannot rebuild the tree, child #{k} cannot point to a node higher up in the tree, it results in an infinite loop."
      end
      return found_match
    else #otherwise, lets cycle through its children (if any)
      infinite_loop = false
      current_types.each do |type|
        infinite_loop = infinite_loop || infinite_loop_exists(NodeClassTest.find_by_name("#{@class_def.name}:#{type}"))
      end
     
      #unmark the current node as found when we step back up above it
      if @types.include? current_node.name_without_prefix
        @types[current_node.name_without_prefix] = false 
      end
      
      return infinite_loop
    end
  end
  
  #function that resets the value of the root based on the updated workspace tree starting at Root
  def reset_root
    user_id, task_id = user_helper
    #node = @class_def.create_nodes('Root', '0', user_id, task_id, root_nodeclass).merge({'_id' => BSON::ObjectId(@class_def.global)})
    tree = @class_def.new_root user_id, task_id
    kit = LDCI::Kit.find_by_uid @class_def.global
    kit.tree_id = tree.id
    kit.save!
    mongo_update_editor tree, []
  end
  
end
