module NodesHelper

  require 'ostruct'

  class StyleConnectionError < StandardError; end;


  def log_annotation(entry)
    entry.unshift 'annotation'
    logger.info entry.map { |x| x.to_s.gsub(/[\t\n]/, ' ') }.join("\t")
  end

  def mongo_insert(entry)
    log_annotation entry
    annotations_connect
    oid = @mongo.ensure_annotations.insert @root
    @kit['tree'] = @root['_id'] = oid
    @kit['_id'] = @mongo.kits.insert @kit
    @mongo.ensure_journals.insert({ :_id => oid, :journal => [ entry ], :namespace => @root['namespace'] })
  end

  def mongo_update(entry)
    log_annotation entry
    annotations_connect
    @mongo.kits.update( { '_id' => @kit['_id'] }, @kit )
    @mongo.ensure_annotations.update( { '_id' => @root['_id'] }, @root )
    logger.debug "Last annotation error: #{@mongo.get_last_annotation_error}"
    @mongo.ensure_journals.update( { '_id' => @root['_id'] }, { '$push' => { :journal => entry } } )
  end
  
  def _mongo_read(kit_oid)
    #annotations_connect
    #@kit = @mongo.kits.find_one( { :_id => BSON::ObjectId(kit_oid) } )    
    @root = @mongo.ensure_annotations.find_one( :_id => @kit['tree'] )
    # @kit = Kit.new kit_oid
    # @root = @kit.tree
  end
  
  # gets current user and task ids
  def user_helper
    task_user = @current_user.current_task_user
    [ @current_user.id, (task_user ? task_user.task_id : nil) ]
  end

  # mainly for the editor, recreates all children
  def create_children(node_id)
    user_id, task_id = user_helper
    node_id = @root['meta']['id'] if node_id == 'root' # saves a second call to mongo_read in class_defs_controller
    @pointer = find_node @root, node_id.to_s
    node = @pointer.node
    
    # other deletions aren't necessary because create_children will overwrite the appropriate fields
    unless node['meta']['list']
      if node['children']
        node['children'].each do |c|
          node.delete c
        end
      end
    end
    #NodeClass.find_by_name(@pointer.type).create_children @root['meta']['last_id'], node, user_id, task_id
    class_def = ClassDef.find_by_name @root['namespace']
    logger.info "x1 #{@pointer.node['meta']['name']}"
    class_def.create_children @root['meta']['last_id'], node, user_id, task_id, get_node_class(@pointer, "#{@root['namespace']}:Root", class_def)
  end

  def gget_node_class(pointer, root_node_class, class_def)
    if pointer.parent.nil?
      class_def.get_node_class root_node_class
    else
      class_def.get_node_class get_node_class(pointer.parent, root_node_class, class_def).get_children_map[pointer.node['meta']['name']]
    end
  end

  def get_node_class(pointer, root_node_class, class_def)
    logger.info "p #{pointer.node['meta']['name']}"
    if pointer.parent.nil?
      logger.info "here1 #{root_node_class}"
      class_def.get_node_class root_node_class
    else
      logger.info "here2 #{root_node_class}"
      x = get_node_class(pointer.parent, root_node_class, class_def)
      logger.info "here3 #{x} #{x.name}"
      y = x.get_children_map
      logger.info "here4 #{y}"
      z = pointer.node['meta']['name']
      logger.info "here5 #{z}"
      class_def.get_node_class y[z]
    end
  end

  def add_child2(root, pointer, user_id, task_id)
    #name, type = NodeClass.find_by_name(@pointer.type).children.split '.'
    class_def = ClassDef.find_by_name root['namespace'].sub(/:.+/, '')
    logger.info "x2 #{pointer.node['meta']['name']}"
    name, type = get_node_class(pointer, "#{root['namespace']}:Root", class_def).children.split '.'
    [ class_def.create_nodes(name, root['meta']['last_id'], user_id, task_id, class_def.get_node_class(type)), type ]
  end

  def add_child(node_id)
    user_id, task_id = user_helper
    @pointer = find_node @root, node_id.to_s
    #node, type = ClassDef.find_by_name(@root['namespace']).add_child2(@root, @pointer, user_id, task_id)
    node, type = add_child2(@root, @pointer, user_id, task_id)
    # @pointer.node['children'] << node
    add_new_node(@pointer, node)
    @pointer.new = node
    @pointer.new_type = type
  end

  def delete_node(node_id)
    user_id, task_id = user_helper
    @pointer = find_node @root, node_id.to_s
    tree_delete_node @pointer
  end

  def change_value(node_id, value)
    user_id, task_id = user_helper
    @pointer = find_node @root, node_id.to_s
    @pointer.node['value'] = value
    @pointer.node['meta']['user'] = user_id
    @pointer.node['meta']['task'] = task_id
  end

  # wraps elaborate_node for starting at the root
  def elaborate_root(node)
    tree = node.tree
    ns = tree.class_def
    @kit.bootstrap_mode = ns.bootstrap_mode
    if tree.version.nil? or tree.version < ns.version
      update_node node, "#{ns.name}:Root", tree.last_iid
      #logger.debug "version has been incremented, rebuilding the tree for namespace #{node['namespace']}}"
      # @root = node#we are using the create_children function which uses @root
      #create_children 'root'
      
      tree.update( :version => ns.version )
      user_id, task_id = user_helper
      entry = [ "updated namespace #{ns.name} to version #{ns.version}", user_id, task_id, Time.now ]
      log_annotation entry
      #tree = NodeClasses::Node.new node
      #tree.move
      je = JournalEntry.new(
                            :tree_id => tree.uid,
                            :namespace => ns.name,
                            :entry => {
                              :message => entry[0],
                              :user_id => user_id,
                              :task_id => task_id,
                              :time => time_now
                            }
                            )
      je.save!
    end
    elaborate_node node, "#{ns.name}:Root", ns
  end

  def update_node(node, node_class_name, last_id)
    node_id = node['meta']['id']
    class_def = ClassDef.find_by_name node_class_name.sub(/:.+/, '')
    node_class = class_def.get_node_class node_class_name
    raise "nil error, node class name: #{node_class_name}" if node_class.nil?
    if node['children']
      cm = node_class.get_children_map
      if not node['meta']['list']
        if cm.size > node['children'].size
          cm.keys.each_with_index do |k, i|
            if node['children'][i] != k
              nc = class_def.get_node_class cm[k]
              user_id, task_id = user_helper
              node['children'].insert i, k
              node[k] = class_def.create_nodes k, last_id, user_id, task_id, nc
              #raise node['children'].to_s
            end
          end
        end
      end
      node['children'].each do |x|
        x = node[x] unless node['meta']['list']
        if x.nil?
          raise node['children'].to_s
        end
        #x['meta']['hide'] = true if meta['hide']
        update_node x, cm[x['meta']['name']], last_id
      end
    end
    node
  end


  def _elaborate_node(node, node_class_name, class_def)
    node.path = ''
    #node.path = if node.parent.nil?
    #              ''
    #            elsif node.parent.parent.nil?
    #              node.index
    #            else
    #              "#{node.parent.path}.#{node.index}"
    #            end
    node.node_class = node_class = class_def.get_node_class(node_class_name)
    raise "nil error, node class name: #{node_class_name}" if node_class.nil?
    node.types = node_class.types
    if node_class.style and node_class.style_name !~ /:empty$/
      css = node_class.style_css
      classes = node_class.style_classes
      
      #this hash can get set in the style editor when css properties are removed and offers a way to reset their values,
      #without requiring a page refresh - currently does not work with selectors
      if !@removed_css_properties.nil?
        if node_class.style_id == @removed_css_properties[:id]
          @removed_css_properties[:list].each do |k, v|
            if v.class == Hash
              if css.include? k
                v.each do |k2, v2|
                  css[k][k2] = v2
                end
              else
                css[k] = v
              end
            else
              css[k] = v
            end
          end
        end
      end
      
      horiz = node_class.style_horizontal ? true : false # wanted to cover the nil case
      #hide = node_class.style.hide ? true : false
    else
      css = {}
      horiz = false
      #hide = false
    end
    if node_class.types.include? 'Label'
      if node_class.children
        node_class.value = { 'label' => node_class.children }
        node_class.children = nil
        node_class.save!
      end
      node.value = node_class.value['label']
    end
    if node_class.types.include? 'Button'
      if node_class.children
        a = node_class.children.split ':'
        node_class.value = { 'label' => a[1], 'message' => a[0] }
        node_class.children = nil
        node_class.save!
      end
      node.value = node_class.value
    end
    if node_class.types.include? 'ButtonGroupRadio'
      node.value.merge! node_class.value
    end
    node.css = css
    node.extra_classes = classes
    node.horiz = horiz
    #meta['hide'] = hide
    if node.children
      cm = node_class.get_children_map
      node.children_array.each do |x|
        if x.nil?
          raise node.children.to_s
        end
        #raise node_class.get_children_map.to_s if cm[x.name].nil? or cm[x.name] == ''
        #x['meta']['hide'] = true if meta['hide']
        elaborate_node x, cm[x.name], class_def
      end
    end
    node
  end

end
