module TreeableHelper

  # root, parent, children, value, leaf, list

  # returns pointers to the node, its parent, and its index within the parent
  # wrapper for find_node_r

  def find_node(iid)
    @last_path = ''
    #pointer = create_pointer root, nil, nil
    iid = iid.to_s # allow someone to pass an integer
    if iid =~ /^(\d+)\.(.+)/
      #p = find_node_r root, $1, nil, nil
      p = find_node_r $1
      if p.nil?
        nil
      else
        #find_node_in_children_by_path p.node, $2
        p.find_node_in_children_by_path $2
      end
    else
      #find_node_r root, id, nil, nil
      find_node_r iid
    end
  end

  # recursively searches for a node with given id
  def find_node_r(iid)
    if self.iid == iid
      #create_pointer node, parent, i
      self
    else
      find_node_in_children iid
    end
  end

  def find_node_in_children(iid)
    #logger.info "y #{pointer.node['meta']['name']}"
    found = nil
    #node = pointer.node
    if @children
      #unless type == :none
      #  node_class = NodeClass.find_by_name(type)
      #  children_map = node_class.get_children_map
      #end
      children_array.each_with_index do |c, i|
        #c = node[c] unless node['meta']['list']
        #type = children_map[c['meta']['name']] unless type == :none
        #p = create_pointer c, pointer, i
        #found = find_node_r c, id, node, i
        found = c.find_node_r iid
        break if found
      end
    end
    found
  end

  def get(path)
    raise 'here'
    return find_node_in_children_by_path path
    #obj = self
    #path.split('.').each do |key|
      #raise 'bad path key' unless key =~ /^[-\w]+$/
      #obj = obj.children[key]
      #break if obj.nil?
    #end
    #obj
  end

  def fnbp(path)
    find_node_in_children_by_path path
  end

  def find_node_in_children_by_path(path)
    #parent = nil
    #i = nil
    node = self
    path.split('.').each do |name|
      if node.list
        node = name =~ /^-?\d+$/ ? node.children[name.to_i] : node.children.first
      else #if node.children.has_key? name
        #node_class = NodeClass.find_by_name(type)
        #children_map = node_class.get_children_map
        #parent = node
        #parent = create_pointer node, parent, i
        #i = node['children'].index name
        raise name if node.children.class == Array
        node = node.children[name]
        #pointer = create_pointer node, pointer, i
        #type = children_map[name]
      end
      return nil if node.nil?
    end
    node
  end

  def get_path_to_node
    if @parent.nil?
      ''
    else
      node = self
      path = []
      while not node.parent.nil?
        path.unshift node.parent.list ? node.parent.children.index(node) : name
        node = node.parent
      end
      path.join '.'
    end
  end

  # handles the connections, not the creation, of nodes
  def add_nodes(nodes)
    @children += nodes
    if self.class < ActiveRecord::Base
      children_nodes.concat nodes.map { |x| x.iid }
      save!
    end
    nodes.each do |node|
      node.parent = self
    end
  end

  # handles the connections, not the creation, of nodes
  def add_node(node, index=nil)
    if index.nil?
      @children << node
    else
      @children.insert index, node
    end
    if self.class < ActiveRecord::Base
      if index.nil?
        children_nodes << node.iid
      else
        children_nodes.insert index, node.iid
      end
      save!
    end
    node.parent = self
  end

  # disconnect node
  def remove_node
    if @parent
      if @parent.list
        @parent.children.delete self
      else
        @parent.children.delete name
      end
      if self.class < ActiveRecord::Base
        @parent.children_nodes.delete iid
        @parent.save!
      end
      @parent = nil
    end
  end

  # disconnect and delete
  def delete_node
    remove_node
    destroy_node if self.class < ActiveRecord::Base
  end

  def delete_all_children
    if list
      @children = []
    else
      @children = {}
    end
    if self.class < ActiveRecord::Base
      self.children_nodes = []
      save!
    end
  end

  def move_node(obj)
    x = obj[:old_position] || obj['old_position']
    y = obj[:new_position] || obj['new_position']
    [ x, y ].each do |z|
      raise "move_node, index not number: #{z} #{z.class}" unless z.class == Fixnum
      raise 'move_node, index out of bounds' unless z > -1 and z < @children.length
    end
    raise 'move_node, indices identical' if x == y
    @children[x], @children[y] = @children[y], @children[x]
    if self.class < ActiveRecord::Base
      children_nodes[x], children_nodes[y] = children_nodes[y], children_nodes[x]
      save!
    end
  end

  def remove_children
    children_array.each { |x| x.parent = nil }
    if @list
      @children = []
    else
      @children = {}
    end
    if self.class < ActiveRecord::Base
      children_nodes = []
      save!
    end
  end

  def delete_children
    remove_children
    destroy_children if self.class < ActiveRecord::Base
  end

  # eliminates subtree from sql backend
  def destroy_node
    destroy_children
    destroy
  end

  # eliminates children from sql backend
  def destroy_children
    children_array.each { |x| x.destroy_node }
  end

  # for now has one purpose:
  # change symbol keys to string keys, which is a constant problem
  def sanitize_value(value)
    case value
    when Hash
      h = {}
      value.each do |k, v|
        h[k.to_s] = v
      end
      h
    else
      value
    end
  end

  # handle the case of simple values, which have to be embedded into a hash
  def change_value_value(value)
    change_value( { 'value' => value } )
  end

  def copy_value(source)
    @value = source.value
    if self.class < ActiveRecord::Base
      self.node_value_id = source.node_value_id
      save!
    end
  end

  def randomize
    if @children and list
      @children.shuffle!
      if self.class < ActiveRecord::Base
        self.children_nodes = @children.map { |x| x.iid }
        save!
      end
    end
  end

  def children_array
    return [] if @children.nil?
    if level == 1
      @children
    else
      @children.values
    end
  end

  def first_value(sel)
    value = find_by_css(sel, nil)[0]
    if value.class == Hash and value.has_key? 'value'
      value['value']
    else
      value
    end
  end

  def find_by_css(sel, array=nil)
    if array.nil?
      array = [ ]
    end
    case sel
    when /^[-\w]+$/
      if name == sel
        if leaf
          array << @value
        else
          array << self
        end
      end
      children_array.each do |c|
        c.find_by_css sel, array
      end
    when /^([-\w]+),\s*(\w+)$/
      if name == $1 or name == $2
        if leaf
          array << @value
        else
          array << self
        end
      end
      children_array.each do |c|
        c.find_by_css sel, array
      end
    end
    array
  end

  def find_nodes_by_css(sel, array=nil)
    if array.nil?
      array = [ ]
    end
    case sel
    when /^[-\w]+$/
      if name == sel
        array << self
      end
      children_array.each do |c|
        c.find_nodes_by_css sel, array
      end
    when /^([-\w]+),\s*(\w+)$/
      if name == $1 or name == $2
        array << self
      end
      children_array.each do |c|
        c.find_nodes_by_css sel, array
      end
    end
    array
  end

  def find_by_reverse_ref_helper(node_type)
    if name == node_type
      return self
    elsif parent.nil?
      return nil
    else
      parent.find_by_reverse_ref_helper node_type
    end
  end

  def find_by_reverse_ref(node_type)
    @reverse_ref ||= []
    @reverse_ref.map { |x| x.find_by_reverse_ref_helper node_type }.compact
  end

  # same as find_by_css but saves the step of @value['value'] when the values have that form
  def find_by_css_value(sel, array=nil)
    if array.nil?
      array = [ ]
    end
    case sel
    when /^[-\w]+$/
      if name == sel
        if leaf
          array << @value['value']
        else
          array << self
        end
      end
      children_array.each do |c|
        c.find_by_css_value sel, array
      end
    end
    array
  end

  def find(klass, array=nil)
    if array.nil?
      array = [ ]
    end
    if self.class == klass
      array << self
    end
    children_array.each do |c|
      c.find klass, array
    end
    array
  end

  def find_by_css_map(node)
    find_by_css(node).map do |x|
      yield x
    end
  end

  def find_by_css_map_add_nil(node, add_nil)
    a = find_by_css(node).map do |x|
      yield x
    end
    if add_nil
      a + yield(nil)
    else
      a
    end
  end

  # for use with #recurse, prints the class
  def puts_class
    puts self.class
  end

  def recurse(method, x=nil)
    if respond_to? method
      if x.nil?
        send method
      else
        send method, x
      end
    end
    unless leaf
      children_array.each do |c|
        c.recurse method, x
      end
    end
  end

  def get_root
    @root
  end

  def tree_uid
    @tree_uid
  end

  def get_nodes(a=[])
    a << self
    unless @leaf
      children_array.each { |x| x.get_nodes a }
    end
    a
  end

  def children_nodes
    @root.all_nodes.select { |x| x.parent_id == id }.sort_by { |x| x.index }
  end

  # def children_nodes
  #   Node.includes(:node_value).where(tree_id: tree_id, parent_id: id, current: true).order(:index).to_a
  # end

  def all_nodes
    @all_nodes
  end

  def initialize_from_sql_root(tree, all_nodes)
    @all_nodes = all_nodes
    initialize_from_sql nil, tree, tree.class_def.inverted_grammar
  end

  # root, parent, children, value, leaf, list
  # ensures the necessary attributes are set when the nodes are backed by sql
  # all_nodes has to be a hash of active record objects
  def initialize_from_sql(parent, tree, g)
    @parent = parent
    @list = level == 1
    @leaf = level == 3
    @tree = tree
    if g[node_class_id]
      self.name = g[node_class_id][:name].split(':').last
    else
      self.name = 'MISSING'
    end
    #initialize the root node of the tree with all tree nodes
    if @parent.nil?
      #set @root to be the Root node, for easier access later
      @root = self
      # @_id = root
      # @_id = tree.uid
      @tree_uid = tree.uid

      @last_iid = tree.last_iid
      @version = tree.version
    else
      @root = @parent.get_root
      @tree_uid = @parent.tree_uid
    end
    #for lists, create a list of children by recursively calling this method for each list item
    if @list
      @children = children_nodes.map { |x| x.initialize_from_sql self, tree, g }
    else
      #loop through the children, and recursively initializing that child and the tree below them
      @children = {}
      children_nodes.each do |c|
        #puts id
        #puts c
        #puts c.class
        #puts all_nodes
        #puts all_nodes.has_key? c
        # c = all_nodes[c]
        # c.name = g[c.node_class_id][:name].split(':').last
        # child_name = c.name
        c.initialize_from_sql self, tree, g
        @children[c.name] = c
      end
    end
    self
  end

  def to_nf2
    h = {}
    # parent_node about half null
    # sort_order, parent_id, unmapped_infoboxes completely null
    # child is almost all null
    keys = %w[
      id
      name
      iid
      node_id
      user_id
      task_id
      list
      leaf
      value
      children_nodes
      uid
      tree_id
      node_class_id
      type
      node_value_id
    ]
    keys.each do |k|
      h[k] = self.send k
    end
    h.to_yaml
  end

  def to_nf3
    h = {}
    keys = %w[
      name
      iid
      user_id
      task_id
      list
      leaf
      value
      children_nodes
      uid
      node_class_id
      type
    ]
    keys.each do |k|
      h[k] = self.send k
    end
    h['value'] = case @value
    when LDCI::Coref
      @value.to_hash
    else
      @value
    end
    h.to_yaml
  end

end
