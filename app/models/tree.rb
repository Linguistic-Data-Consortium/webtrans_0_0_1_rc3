class Tree < ActiveRecord::Base
  # attr_accessible :class_def_id, :last_iid, :uid, :version
  has_many :kits
  has_many :nodes
  belongs_to :class_def
  # belongs_to :source
  # delegate :node_classes, :name, :to => :class_def, :prefix => true
  attr_accessor :testt

  def class_def_test
    ClassDefTest.find(self.class_def_id)
  end

  def class_def_node_classes
    (@testt ? class_def_test : class_def).node_classes
  end

  def class_def_name
    (@testt ? class_def_test : class_def).name
  end

  def self.load_tree_config(db)
    @@load_tree_config = db
  end

  def _new_nodes
    Node.where( :tree_id => id ).where( 'iid > ?', last_iid )
  end

  @@counter = "0" * 16

  def assign_id
    self.uid = ("%x" % Time.now.to_i) + @@counter.succ!
    raise "duplicate tree uid #{uid}" if Tree.find_by_uid uid
  end

  def sequel_connect
    @@db ||= Sequel.connect @@load_tree_config
  end

  def load_tree
    return @rroot if @rroot
    db = sequel_connect
    nodes = {}
    db[:nodes].where( tree_id: id ).each do |n|
      nodes[n[:iid]] = n
    end
    nv_ids = nodes.values.map { |x| x[:node_value_id] }
    nvs = {}
    db[:node_values].where( id: nv_ids ).each do |nv|
      nvs[nv[:id]] = nv[:value]
    end
    @rroot = Node.new nodes['0'], nil, nodes, self, nvs
    apply_type_hierarchy @rroot
    @rroot
  end
  def apply_type_hierarchy(root)
    node_classes = {}
    NodeClass.where( name: @rroot.index_by_type.keys.map { |x| x.split('::')[2..3].join(':') } ).each do |x|
      node_classes[x.id] = x
    end
    ids = node_classes.values.map { |x| x.parent_id }.uniq.compact
    while ids.size > 0
      NodeClass.where( id: ids ).each do |x|
        node_classes[x.id] = x
      end
      ids = node_classes.values.map { |x| x.parent_id }.uniq.compact - node_classes.keys
    end
    node_classes.each do |k, v|
      case v.parent_id
      when 6472 # Ref
        root.index_by_type["LDCI::NodeClasses::#{v.name.sub(':','::')}"].each do |ref|
          n = root.index_by_iid[ref.value['value']]
          ref.value = n
          next if n.nil?
          n.reverse_ref ||= []
          n.reverse_ref << ref
        end
      end
    end
  end




  def tree
    @tree ||= create_tree_sql
  end

  def reset
    @nodes = {}
    @tree = create_tree_sql
  end

  def find_values_by_css(sel)
    case sel
    when /^[-\w]+\Z/
      NodeValue.where( id: nodes.where( name: sel ).pluck(:node_value_id) ).pluck(:value).map { |x| YAML.load x }
    else
      []
    end
  end


  # duplicate a tree
  def fork
    t = Tree.new
    t.assign_id
    [ :class_def_id, :version, :last_iid, :source_id, :user_id ].each do |x|
      t.send "#{x}=", send(x)
    end
    t.status = 'forking'
    t.save!
    nodes.find_in_batches do |b|
      Tree.transaction do
        b.each do |node|
          n = Node.new
          %w[ name iid user_id task_id list leaf value children_nodes uid node_class_id type node_value_id ].each do |x|
            n.send "#{x}=", node.send(x)
          end
          n.node_id = "#{t.uid}-#{n.iid}"
          n.tree_id = t.id
          n.save!
        end
      end
    end
    t.status = status
    t.save!
    t
  end

  def equivalent?(t)
    strings = []
    [ self, t ].each do |tt|
      root = tt.tree # make sure tree is fully instantiated
      strings << tt.get_node_hash.values.map { |node| node.to_nf3 }.join
      open( "/tmp/tree#{strings.length}", 'w' ){ |f| f.puts strings[-1] }
    end
    strings[0] == strings[1]
  end

  # creates the node objects, adds them to @nodes hash
  def create_nodes(iids=nil)
    @nodes = {} unless @nodes
    x = Time.now
    a = Node.where( :tree_id => id )
    a = a.where( :iid => iids ) if iids # narrow down the select if iids are given
    # a.includes( [ :node_value, :node_class ] ).each do |n|
    a.includes(:node_value).each do |n|
      @nodes[n.iid] = n
      if @init_node_values[n.node_value_id].nil?
        if n.node_value_id == 0
          v = { value: nil }
        else
          v = { value: n.node_value.value }
        end
        # @init_node_values[n.node_value_id] = (v.class == String and v =~ /^---\s/) ? YAML.load(v) : v
        @init_node_values[n.node_value_id] = v
      end
    end
  end

  def create_tree_sql
    root = Node.where(tree_id: id, iid: 0).first
    all_nodes = Node.includes(:node_value).where(tree_id: id, current: true).order(:index).to_a
    root.initialize_from_sql_root self, all_nodes if root # tree could be empty
  end

  def create_tree_sql2(all_nodes)
    root = all_nodes.select { |x| x.tree_id == id and x.iid == 0 }.first
    root.initialize_from_sql_root self, all_nodes if root # tree could be empty
  end

  def get_node(iid)
    create_tree_sql unless @nodes
    @nodes[iid]
  end

  def get_node_hash
    @nodes
  end

  def root
    get_node '0'
  end

  def delete_all_children_from_list_at_path(path)
  #   tree.fnbp(path).children_array.map do |node|
  #     delete_node node
  #   end
    list = tree.fnbp path
    list.children_nodes.each { |id| @nodes.delete id }
    list.delete_all_children
    list
  end

  def delete_node(node)
    @nodes.delete node.iid
    node.delete_node
    node
  end

  def move_node(list, user_id, task_id, value)
    list.user_id = user_id
    list.task_id = task_id
    list.move_node value
    list
  end

  def change_value(node, user_id, task_id, value)
    node.user_id = user_id
    node.task_id = task_id
    node.change_value value
    node
  end

  def copy_value(node, user_id, task_id, source)
    node.user_id = user_id
    node.task_id = task_id
    node.copy_value source
    node
  end

  def randomize_node(node, user_id, task_id)
    node.user_id = user_id
    node.task_id = task_id
    node.randomize
    node
  end

  def execute_annotation_set(ann_set, user_id, task_id)
    ann_set.annotations.each do |ann|
      node = tree.find_node ann.node_iid
      case ann.message
      when 'add'
        if ann.journal_entry and ann.journal_entry.entry['value'].class == Fixnum
          add_new_nodes node, user_id, task_id, ann.journal_entry.entry['value']
        else
          add_new_node node, user_id, task_id
        end
      when 'change'
        if ann.journal_entry and ann.journal_entry.entry.has_key? 'value'
          change_value node, user_id, task_id, ann.journal_entry.entry['value']
        end
      when 'randomize'
        randomize_node node, user_id, task_id
      end
    end
  end

  def execute_annotations(annotations)
    annotations.each do |annotation|
      case annotation.message
      when "new_root"
        puts annotaion.message
      when "change"
        puts annotaion.message
      when "create_mention"
        puts annotaion.message
      when "add"
        puts annotaion.message
      when "destroy_mention"
        puts annotaion.message
      when "create_entity"
        puts annotaion.message
      when "add_mention"
        puts annotaion.message
      else
        raise "unknown message in annotation #{annotation.id}"
      end
    end
  end

  def add_new_nodes(node, user_id, task_id, ntimes)
    #num.times { add_new_node node, user_id, task_id }
    name, type = node.node_class.children.split '.'
    new_node_class = get_node_class type
    num = last_iid.dup
    nde_id = Nde.where(tree_id: node.tree_id, iid: node.iid).pluck(:id).first
    new_nodes = []
    ntimes.times do
      Tree.transaction do
        new_nodes << new_node_class.create_nodes(name, num, user_id, task_id, self, nde_id, new_nodes.length)
      end
    end

    create_nodes( nodes.pluck(:iid) - @nodes.keys )
    self.last_iid = num
    save!
    tree.last_iid = num

    node.add_nodes new_nodes # treeable function, handles connection
    new_nodes.each do |new_node|
      new_node.initialize_from_sql node, @nodes, self, @init_node_classes, @init_node_values
    end
    new_nodes[-1]
  end

  # wraps the treeable function of same name, but handles creation of nodes
  def add_new_node(node, user_id, task_id, index=nil)
    name, type = node.node_class.children.split '.'
    new_node_class = get_node_class type
    num = last_iid.dup
    #puts "add new node 44 #{Time.now}"
    nde_id = Nde.where(tree_id: node.tree_id, iid: node.iid).pluck(:id).first
    nde_c = Nde.where(parent_id: nde_id).count
    new_node = new_node_class.create_nodes(name, num, user_id, task_id, self, nde_id, nde_c)
    #puts "add new node 54 #{Time.now}"
    #puts
    create_nodes( nodes.pluck(:iid) - @nodes.keys )
    self.last_iid = num
    save!
    tree.last_iid = num
    node.add_node new_node, index # treeable function, handles connection
    new_node.initialize_from_sql node, @nodes, self, @init_node_classes, @init_node_values
    new_node
  end

  # update children based on a change in the node class
  # right now just add new children that aren't present
  # or reorder children
  # not for list nodes yet
  def refresh_children(node, user_id, task_id)
    new_children = node.node_class.children.split ','
  end

  def refresh
    puts tree.node_class.children.split ','
  end

  # wraps elaborate_node for starting at the root
  def elaborate_root(user_id, task_id)
    # if version.nil? or version < class_def.version
    #   update_node tree, "#{class_def.name}:Root", last_iid

    #   version = class_def.version
    #   save!

    #   entry = [ 'update node', "updated namespace #{class_def.name} to version #{class_def.version}", user_id, task_id, Time.now ]
    #   logger.info entry.join "\t"

    #   je = LDC::Annotation::JournalEntry.new(
    #                         :tree_id => uid,
    #                         :namespace => class_def.name,
    #                         :entry => {
    #                           :message => entry[0],
    #                           :user_id => user_id,
    #                           :task_id => task_id,
    #                           :time => Time.now
    #                         }
    #                         )
    #   je.save!
    # end
    elaborate_node tree
  end

  # replicates NodeClass#types but takes advantage of the local cache
  def node_class_types(nc)
    type = nc
    a = []
    while type != nil
      a << type.name #.sub(/.+:/, '')
      a << 'List' if type.name == 'EmbeddedList'
      if type.parent_id and @all_node_classes[type.parent_id].nil?
        @all_node_classes[type.parent_id] = type.parent
      end
      type = @all_node_classes[type.parent_id]
    end
    a << 'Node' unless a[-1] == 'Node'
    a
  end

  def elaborate_node(node)
    node_class = get_node_class node.node_class_id
    raise "node has no node class, node id: #{node.id}" if node_class.nil?
    node.types = node_class_types node_class
    if false #node_class.style and node_class.style_name !~ /:empty$/
      css = node_class.style_css
      classes = node_class.style_classes
      horiz = node_class.style_horizontal ? true : false # wanted to cover the nil case
    else
      css = {}
      horiz = false
    end
    if node.types.include? 'Label'
      node.value = node_class.value['label']
    end
    if node.types.include? 'Button'
      node.value = node_class.value
    end
    node.css = css
    if node.children
      node.children_array.each do |x|
        if x.nil?
          raise node.children.to_s
        end
        elaborate_node x
      end
    end
    node
  end

  def class_def_node_classes
    (@testt ? class_def_test : class_def).node_classes
  end

  def class_def_name
    (@testt ? class_def_test : class_def).name
  end

  # this caching scheme is similar to eager loading, so why not use that?  I think because we don't want to *force* eager loading
  #function that returns a node class by name via the class def's node classes array (now works with id too)
  def get_node_class(name)
    if @all_node_classes.nil?
      @all_node_classes = {}
      if $dont_include_style
        class_def_node_classes.each do |nc|
          @all_node_classes[nc.name] = nc
          @all_node_classes[nc.id] = nc
        end
      else
        class_def_node_classes.each do |nc|
          @all_node_classes[nc.name] = nc
          @all_node_classes[nc.id] = nc
        end
      end
    end
    if @all_node_classes[name].nil?
      nc_class = NodeClass
      case name
      when String
        nc = nc_class.find_by_name name
      else
        nc = nc_class.find name
      end
      raise name if nc.nil?
      @all_node_classes[nc.name] = nc
      @all_node_classes[nc.id] = nc
    end
    @all_node_classes[name]
  end

  #function that returns the root node class associated with this tree
  def get_root_node_class
     get_node_class "#{class_def_name}:Root"
  end

  def new_root(user_id, task_id)
    Tree.transaction do
      num = '0'
      root = get_root_node_class.create_nodes('Root', num, user_id, task_id, self)
      update( :last_iid => num )
    end
  end

  def create_mention(node, value)
    coref = node.value
    mention = LDCI::Mention.new
    mention.id = value['_id']
    mention.ref = value['_ref']
    coref.add_mention mention
    coref.entity_add_mention value['eid'], value['_id']
    save_coref
  end

  def destroy_mention(node, value)
    coref = node.value
    coref.entity_remove_mention value['eid'], value['mid']
    coref.remove_mention value['mid']
    save_coref
  end

  def add_mention(node, value)
    coref = node.value
    coref.entity_add_mention value['eid'], value['mid']
    save_coref
  end

  def create_entity(node, value)
    coref = node.value
    coref.add_entity_to_group value['eid'], value['gid']
    value['mids'].each do |mid|
      coref.entity_add_mention value['eid'], mid['_id']
    end
    save_coref
  end

  def destroy_entity(node, value)
    coref = node.value
    coref.remove_entity_from_group value['eid'], value['gid']
    save_coref
  end

  def rename_entity(node, value)
    coref = node.value
    coref.rename_entity_in_group value['eid'], value['new_name']
    save_coref
  end

  def update_order(node, value)
    coref = node.value
    coref.update_order_in_group value['gid'], value['order']
    save_coref
  end

  def save_coref
    nv = tree.coref_node.node_value
    nv.value = tree.coref.to_hash.to_yaml
    nv.save!
  end

  def grammar
    @grammar ||= class_def.get_grammar
  end

  def inverted_grammar
    @inverted_grammar ||= class_def.get_inverted_grammar
  end

  # constructs the tree and then checks it against the grammar
  def confirm
    #puts self.id
    #if self.id == 446264
    #  $skip = false
    #end
    #return if $skip
    ids = self.kits.pluck(:task_id)
    #return unless ids.include?(784) || ids.include?(785) || ids.include?(786)
    return true if [ 409765, 444424, 446264 ].include? self.id
    root = tree
    return if root.nil?
    #puts [ root.id, root.children['Left'].id, root.fnbp('Left.Document').id ].join(' ')
    root.confirmr self
  end

  def confirm2
    root = tree
    return if root.nil?
    root.confirmr self
  end

  def set_parent_id
    Tree.transaction do
      #if self.nodes.where(parent_node: nil).where('name != "Root"').count > 0
      self.nodes.update_all(parent_id: nil)
        t = tree
        t.set_parent_id if t
      #end
    end
  end

  def check_grammar
    g = get_grammar
    g.each do |k, v|
      if v[:parent_id] == 3
        raise "bad list length #{k}" unless v[:children].length == 1
        raise "bad list child #{k}" unless g[v[:children].first][:parent_id] == 2
      elsif v[:parent_id] == 2 or v[:parent_id] == 1
        raise "bad listitem length #{k}" unless v[:children].length > 0
        raise "bad listitem child #{k}" if v[:children].map { |x| g[x][:parent_id] }.include?(2)
      else
        raise "bad leaf #{k}" if v[:children]
      end
    end
  end

end
