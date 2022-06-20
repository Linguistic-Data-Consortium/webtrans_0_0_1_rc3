class Node < ActiveRecord::Base
  belongs_to :tree, optional: true
  belongs_to :node_class, optional: true
  belongs_to :node_value, optional: true
  belongs_to :nde_value, optional: true
  belongs_to :parent, optional: true, class_name: 'Node'

  attr_accessor :types, :css, :extra_classes, :horiz, :children, :child

  include TreeableHelper

  # attr_accessor :value, :coref, :coref_node, :types, :css, :horiz, :path, :mention, :speaker_id, :extra_classes
  # attr_accessor :skip_over, :skip_into, :all_nnodes, :children, :root, :parent, :last_iid
  # attr_accessor :nde

  def self.copy_from_nds
    Nd.find_in_batches do |b|
      b.each do |nd|
        node = Node.where(id: nd.id).first_or_create
        [ :user_id, :task_id, :parent_id, :tree_id, :node_class_id, :index, :iid, :level, :nde_value_id, :current ].each do |x|
          node.send "#{x}=", nd.send(x)
        end
        node.save!
      end
    end
    NodeClass.all.each do |nc|
      Node.where(node_class_id: nc.id).update_all(name: nc.name.split(':').last)
    end
  end

  def to_client_hash(list=false)
    h = {}
    meta = h['meta'] = {}
    meta['name'] = name
    meta['id'] = iid
    meta['nid'] = id
    meta['user'] = user_id
    meta['task'] = task_id
    # meta['node_id'] = node_id
    meta['list'] = level == 1
    # meta['child'] = child if child
    meta['node_class_id'] = node_class_id
    if @root_node == self
      h['namespace'] = tree.class_def.name
      h['version'] = tree.version
      h['_id'] = tree.uid unless tree.nil? or tree.uid.nil?
    end
    if level == 3
      case value
      when 1 #LDCI::Coref, LDCI::Audio
        h['value'] = value.to_hash
      when 2 #LDC::Source
        h['value'] = value.to_interchange(1)
      else
        h['value'] = value
      end
    else
      # g = tree.class_def.inverted_grammar
      # @children ={}
      # g[node_class_id][:children].each do |c|
      #   @children = Nd.where(tree_id: tree_id, parent_id: id)
      # end
      if level == 1
        if list
          h['children'] = @children.map { |c| c.to_client_hash }
        else
          h['children_iids'] = @children.map { |c| c.iid }
          h['children'] = []
          h['children'] = @children.map { |c| c.to_client_hash }
        end
      else
        h['children'] = @children.keys
        @children.each do |k, v|
          h[k] = v.to_client_hash
          # h[k] = v.node_class_id
        end
      end
    end
    h
  end

  def change_value(value)
    value = sanitize_value value
    @value = value
    NodeValue.transaction do
      self.node_value = NodeValue.new_value value
      save!
    end
  end

  def value
    @value ||= get_value
  end

  # private

  def get_value
    if node_value_id == 0
      { value: nil }
    elsif node_value.source_id
      { source_id: node_value.source_id }
    elsif node_value.text
      {
        docid: node_value.docid,
        beg: node_value.begi,
        end: node_value.endi,
        text: node_value.text
      }
    elsif node_value.begr
      h = {
        docid: node_value.docid,
        beg: node_value.begr.to_f,
        end: node_value.endr.to_f
      }
      h[:play_head] = node_value.play_head.to_f if node_value.play_head
      h[:value] = node_value.value if node_value.value
      # h[:timestamps] = node_value.timestamps if node_value.timestamps
      h
    else
      { value: node_value.value }
    end
  end

  def get_tree # because #tree is an active record association, but the Tree object may already be loaded
    @tree
  end

  def child_array
    return
    if list
      children
    else
      children.values
    end
  end

  def set_parent_ids_default
    return
    cids = children_array.map(&:id)
    Node.where(id: cids).update_all(parent_id: self.id)
  end

  def get_node_list_root(tables)
    return
    a, b, namespace, class_name = self.type.split '::'
    raise "get_node_list_root has to be called on Root, not: #{class_name}" if class_name != 'Root'
    s = ''
    case namespace
    when 'Chunker'
      eval_using_defaults namespace: namespace,
                          lists:     %w[ ChunkList ],
                          listitems: %w[ ChunkListItem ]
    else
      raise "bad namespace: #{namespace}"
    end
    get_node_list_root2 tables
  end

  def eval_using_defaults(namespace:, lists:, listitems:)
    return
    s = ''
    s << "def get_node_row; get_node_row_default; end; "
    listitems.each do |x|
      s << "class LDCI::NodeClasses::#{namespace}::#{x}; def get_node_row; get_node_row_default; end; end; "
    end
    lists.each do |x|
      s << "class LDCI::NodeClasses::#{namespace}::#{x}; def get_node_list(tables); get_node_list_default tables; end; end; "
    end
    eval s
  end

  def get_node_row_default
    return
    h = {}
    # all[self.id] = h
    # h[:iid] = self.iid
    # h[:name] = self.name
    children_array.each do |c|
      hh = {}
      h[c.id] = hh
      hh[:iid] = c.iid
      hh[:name] = c.name
      hh[:value] = c.node_value.value unless c.list
    end
    h
  end

  def snake(s)
    # patterns come from rails
    s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
  end

  def get_node_list_default(tables)
    return
    name = snake "#{self.name}Items"
    tables[name] ||= []
    table = tables[name]
    children_array.each do |c|
      table << get_node_list_default_helper(c)
    end
    table
  end

  def get_node_list_root2(tables)
    return
    name = snake "#{self.name}Items"
    tables[name] ||= []
    table = tables[name]
    row = {}
    row['list_id'] = self.tree_id
    table << get_node_list_default_helper2(self, row)
    table
  end

  def get_node_list_default_helper(c)
    return
    row = {}
    row['list_id'] = self.id
    row['list_iid'] = self.iid
    # row[:children] = c.get_node_row
    get_node_list_default_helper2 c, row
  end

  def get_node_list_default_helper2(c, row)
    return
    row['row_id'] = c.id
    row['row_iid'] = c.iid
    c.get_node_row.each do |k, v|
      name = snake v[:name]
      row["#{name}_id"] = k
      row["#{name}_iid"] = v[:iid]
      if v[:value]
        YAML.load(v[:value]).each do |kk, vv|
          row["#{name}_#{kk}"] = vv.class == Array ? vv.join(',') : vv
        end
      end
    end
    row
  end

  def _move_tree
    raise if root.nil?
    puts root
    puts "begin transaction #{Time.now}"
    Nnode.transaction do
      Nnode.destroy_all(:root => root)
      puts "begin move #{Time.now}"
      move
      puts "end move #{Time.now}"
    end
    puts "end transaction #{Time.now}"
  end

  def fix_tree
    raise
    if @node_id[0] == '-'
      @root = @pparent_node.root unless @pparent_node.nil?
      @node_id = "#{@root._id}-#@id"
    end
    unless @leaf
      child_array.each { |x| x.fix_tree }
    end
  end

  def to_a
    if leaf
      s = value.to_s
      if s.length > 0
        [ name, 'id', "node-#{id}", s ]
      else
        []
      end
    else
      temp1 = []
      child_array.each do |c|
        next if @skip_over
        temp2 = c.to_a
        if temp2.size > 0
          if c.skip_into
            temp1.concat temp2[-1]
          else
            temp1 << temp2
          end
        end
      end
      if temp1.size > 0
        [ name, 'id', "node-#{id}", temp1 ]
      else
        []
      end
    end
  end

  # Returns xml representation of node. If a leaf, @leaf = true, returns value
  # else returns node as a container element for children.
  # Returns Nokogiri::XML::Element object. Takes parent element as argument
  def to_element(parent)
    send((leaf ? :to_leaf_element : :to_branch_element), parent)
  end

  # If node is a container, not a leaf, returns element containing children
  # as sub-elements.
  def to_branch_element(parent)
    element = parent.document.create_element name, :id => iid
    case children
      when Hash
        children.values.map do |v|
          case v
            when Array
              v
            else
              [v]
          end
        end.flatten
      else
        children
    end.each { |child| element << child.to_element(parent) }
    element
  end

  # If node is a leaf, check if it has an overloaded 'to_element' method, if
  # so call it. Else if a datastructure return JSON version of value, else
  # return string representation.
  def to_leaf_element(parent)
    element = parent.document.create_element name, :id => iid
    if value.respond_to? :to_element
      element << value.to_element(element)
    else
      if value
        element.content =
          if value.class == Hash and value.count == 1 and (value.key? 'value' or value.key? :value)
            _, v = value.first
            case v
              when Enumerable
                element[:type] = 'application/json'
                v.to_json
              else
                v
            end
          else
            case value
              when Enumerable
                element[:type] = 'application/json'
                value.to_json
              else
                value
            end
          end
      end
    end
    element
  end

  def set_ids(last_iid)
    self.iid = last_iid.succ!.dup
    unless leaf
      child_array.each { |x| x.set_ids last_iid }
    end
  end

  def create_value
    raise 'dont use again without fixing'
    v = attributes['value']
    if v
      vv = LDCI::NodeValue.create(:value => v.to_yaml)
      self.node_value_id = vv.id
      save!
    end
  end

  # prints a normal form of the trees for comparison
  def to_nf1(a=[])
    h = {}
    a << h
    h['parent'] = @parent.iid unless @parent.nil? # should equal parent_node
    h['namespace'] = @namespace
    h['root'] = @root.iid unless @root.nil? or @root.iid.nil?
    h['tree'] = @tree_uid unless @tree_uid.nil?
    if iid == '0'
      h['last_id'] = @last_iid unless @last_iid.nil?
    end
    h['name'] = name unless name.nil?
    h['id'] = iid unless iid.nil?
    h['node_id'] = node_id unless node_id.nil?
    h['user'] = user_id unless user_id.nil?
    h['task'] = task_id.to_i unless task_id.nil?
    h['list'] = list unless list.nil?
    h['child'] = child unless child.nil?
    h['leaf'] = leaf unless leaf.nil?

    if iid == '0'
      h['version'] = @version.to_i if @version
      if tree and tree.kits and tree.kits[0]
        k = tree.kits[0]
        h['namestring'] = k.meta['namestring'] unless k.meta['namestring'].nil?
        h['kbptype'] = k.meta['kbptype'] unless k.meta['kbptype'].nil?
        h['refdoc'] = k.meta['refdoc'] unless k.meta['refdoc'].nil?
      end
    end
    h['value'] = @value unless @value.nil?
    if @value
      case @value
      when Hash
        if @value.has_key? 'value'
          h['value'] = @value['value']
        else
          h['value'] = @value
        end
        if h['value'].nil?
          h.delete 'value'
        end
      when String, Array
        h['value'] = @value
      when LDCI::Coref, LDCI::Audio
        h['value'] = @value.to_hash
      when LDC::Source
        h['value'] = @value.to_interchange
      else
        puts @value.class
        puts h
        raise 'unknown value type'
      end
    end
    case @children
    when Array
      h['children'] = @children.map { |x| x.iid }
      @children.each { |x| x.to_nf1 a }
    when Hash
      h['children'] = @children.values.map { |x| x.iid }
      @children.values.each { |x| x.to_nf1 a }
    when NilClass
      h['children'] = []
    else
      raise 'unknown children type'
    end
    return a.to_yaml if @parent.nil?
  end

  # same as nf1 but without :tree and :node_id which have the tree uid.  multiple runs of tree creation
  # should reproduce identical nfs, except for the differnt tree uids.
  def to_nf2(a=[])
    h = {}
    a << h
    h['parent'] = @parent.iid unless @parent.nil? # should equal parent_node
    h['namespace'] = @namespace
    h['root'] = @root.iid unless @root.nil? or @root.iid.nil?
    if iid == '0'
      h['last_id'] = @last_iid unless @last_iid.nil?
    end
    h['name'] = name unless name.nil?
    h['id'] = iid unless iid.nil?
    h['user'] = user_id unless user_id.nil?
    h['task'] = task_id.to_i unless task_id.nil?
    h['list'] = list unless list.nil?
    h['child'] = child unless child.nil?
    h['leaf'] = leaf unless leaf.nil?

    if iid == '0'
      h['version'] = @version.to_i if @version
      if tree and tree.kits and tree.kits[0]
        k = tree.kits[0]
        h['namestring'] = k.meta['namestring'] unless k.meta['namestring'].nil?
        h['kbptype'] = k.meta['kbptype'] unless k.meta['kbptype'].nil?
        h['refdoc'] = k.meta['refdoc'] unless k.meta['refdoc'].nil?
      end
    end
    h['value'] = @value unless @value.nil?
    if @value
      case @value
      when Hash
        if @value.has_key? 'value'
          h['value'] = @value['value']
        else
          h['value'] = @value
        end
        if h['value'].nil?
          h.delete 'value'
        end
      when String, Array
        h['value'] = @value
      when LDCI::Coref, LDCI::Audio
        h['value'] = @value.to_hash
      when LDC::Source
        h['value'] = @value.to_interchange
      else
        puts @value.class
        puts h
        raise 'unknown value type'
      end
    end
    case @children
    when Array
      h['children'] = @children.map { |x| x.iid }
      @children.each { |x| x.to_nf2 a }
    when Hash
      h['children'] = @children.values.map { |x| x.iid }
      @children.values.each { |x| x.to_nf2 a }
    when NilClass
      h['children'] = []
    else
      raise 'unknown children type'
    end
    return a.to_yaml if @parent.nil?
  end

  def indexx
    if @pparent_node.nil?
      ''
    elsif @pparent_node.list
      @pparent_node.children.index self
    else
      name
    end
  end

  def puts_class
    puts self.class
  end

  def add_to_map(map)
    map[iid] = self
  end

  # converts coref mention references to actual object pointers
  def resolve_mention_references
    if coref
      map = {}
      recurse :add_to_map, map
      coref.mentions.each do |k, v|
        v.ref = map[v.ref]
        v.ref.mention = v
      end
    end
  end

  def copy_to_path_from_existing_node(node:, old_path:, new_path:)
    n = fnbp(new_path)
    raise "new tree doesn't have path: #{new_path}" if n.nil?
    nn = node.fnbp(old_path)
    raise "old tree doesn't have path: #{old_path}" if nn.nil?
    n.update(node_value_id: nn.node_value_id)
  end

  def init_list_from_existing_node(path:, node:)
    initp path, node.fnbp(path)
  end

  def copy_to_path_from_existing_node_simplified(paths:, node:)
    paths.each do |path|
      copy_to_path_from_existing_node node: node, old_path: path, new_path: path
    end
  end

  def initp(path, list, cc=nil)
    nlist = fnbp(path)
    nlist.init_list list, cc if nlist
  end

  def initp1(path, list, cc, kc)
    nlist = fnbp(path)
    nlist.init_list1 list, cc, kc if nlist
  end

  def initp2(path, list, cc, kc)
    nlist = fnbp(path)
    nlist.init_list2 list, cc, kc if nlist
  end

  def convert_list(list, node_list, cc=nil)
    return if list.count == 0
    #node_list = fnbp node_path
    c = list.count
    #c -= 1 if node_list.children.count == 1
    c -= 1 if children.count == 1
    if cc
      # @tree.add_new_nodes node_list, @user_id, @task_id, cc
      @tree.add_new_nodes self, @user_id, @task_id, cc
      #node_list.children.last(cc).zip(list).each do |node, x|
      children.last(cc).zip(list).each do |node, x|
        x.node = node
        yield x, node
      end
    else
      # @tree.add_new_nodes node_list, @user_id, @task_id, c
      @tree.add_new_nodes self, @user_id, @task_id, c
      #node_list.children.zip(list).each do |node, x|
      children.zip(list).each do |node, x|
        x.node = node
        yield x, node
      end
    end
  end

  def init_list(list, cc=nil)
    list = list.children if list.class <= Node
    c = list.count
    return if c == 0
    #node_list = fnbp node_path
    #c -= 1 if node_list.children.count == 1
    c -= 1 if children.count == 1
    if cc
      # @tree.add_new_nodes node_list, @user_id, @task_id, cc
      @tree.add_new_nodes self, @user_id, @task_id, cc
      #node_list.children.last(cc).zip(list).each do |node, x|
      children.last(cc).zip(list).each do |node, x|
        x.node = node if x.respond_to? :node
        node.init x
      end
    else
      # @tree.add_new_nodes node_list, @user_id, @task_id, c
      @tree.add_new_nodes self, @user_id, @task_id, c
      #node_list.children.zip(list).each do |node, x|
      children.zip(list).each do |node, x|
        x.node = node if x.respond_to? :node
        node.init x
      end
    end
  end
  def init_list1(list, cc, kc)
    list = list.children if list.class <= Node
    c = list.count
    cc = c if cc.nil?
    return if c == 0
    #node_list = fnbp node_path
    #c -= 1 if node_list.children.count == 1
    c -= 1 if children.count == 1
    if cc
      # @tree.add_new_nodes node_list, @user_id, @task_id, cc
      @tree.add_new_nodes self, @user_id, @task_id, cc
      #node_list.children.last(cc).zip(list).each do |node, x|
      entities = kc.entities
      children.last(cc).zip(list.last(cc)).each do |node, x|
        node.init1 x, kc
        entities[x.iid] = node.iid
      end
    else
      # @tree.add_new_nodes node_list, @user_id, @task_id, c
      @tree.add_new_nodes self, @user_id, @task_id, c
      #node_list.children.zip(list).each do |node, x|
      children.zip(list).each do |node, x|
        node.init1 x, kc
      end
    end
  end
  def init1(node, kc)
    copy_to_path_from_existing_node_simplified node: node, paths: %w[ ResponseID FillerAssessment FillerMentionType JustificationAssessment EntityRef ]
  end
  def init_list2(list, cc, kc)
    list = list.children if list.class <= Node
    c = list.count
    cc = c if cc.nil?
    return if c == 0
    #node_list = fnbp node_path
    #c -= 1 if node_list.children.count == 1
    c -= 1 if children.count == 1
    if cc
      # @tree.add_new_nodes node_list, @user_id, @task_id, cc
      @tree.add_new_nodes self, @user_id, @task_id, cc
      #node_list.children.last(cc).zip(list).each do |node, x|
      entities = kc.entities
      children.last(cc).zip(list.last(cc)).each do |node, x|
        node.init2 x, kc
        entities[x.iid] = node.iid
      end
    else
      # @tree.add_new_nodes node_list, @user_id, @task_id, c
      @tree.add_new_nodes self, @user_id, @task_id, c
      #node_list.children.zip(list).each do |node, x|
      children.zip(list).each do |node, x|
        node.init2 x, kc
      end
    end
  end
  def init2(node, kc)
    copy_to_path_from_existing_node_simplified node: node, paths: %w[ HandleMentionRef ]
  end

  def confirm(tree, inverse)
    #puts node.inspect if node.name =~ /EntityListItem/
    #return unless tree_id == 383111
    return if level == 3
    g = inverse[node_class_id]
    raise "bad grammar #{name}" unless g[:name].split(':').last == name
    raise "bad grammar 1" unless g[:name] == node_class.name
    gc = g[:children]
    return if gc.nil?
    raise "bad grammar 2" unless gc.class == Array
    # raise children.count.to_s if name == 'SegmentListItem' and id != 23
    if level == 1
      if gc.length == 1
        k = gc.first
        children.each do |x|
          if x.node_class_id == k
            x.confirm tree, inverse
          else
            raise GrammarTreeError, message: "node #{x.name}, #{x.node_class_id} doesn't match grammar #{k}", tree: tree, node: self
          end
        end
      else
        raise GrammarTreeError, message: "list node #{name} has grammar #{grammar.inspect}", tree: tree, node: self
      end
    else
      c1 = children.count
      c2 = gc.count
      # if c1 != c2
      #   raise gc.join ','
      #   raise children.values.map { |x| x.name }.join  ','
      # end
      if c1 == c2
        children.zip(gc).each do |kv, id|
          k, v = kv
          if v.node_class_id == id
            v.confirm tree, inverse
          else
            #x = correct tree
            raise GrammarTreeError, message: "node #{k}, #{v.node_class_id} doesn't match grammar #{id}", tree: tree, node: self
          end
        end
      else
        confirm_mismatch tree, c1, c2
      end
    end
  end

  def confirm_mismatch(tree, c1, c2)
    raise GrammarTreeError, message: "mismatch #{c1} #{c2}, node: #{id}, #{name}", tree: tree, node: self
  end

  def inverted_grammar
    @inverted_grammar ||= tree.inverted_grammar
  end

  def confirmr(tree)
=begin
    # inverts the grammar for convenience
    inverse = {}
    grammar.each do |k, v|
      inverse[grammar[k][:id]] = { name: k }
      inverse[grammar[k][:id]][:children] = v[:children].map { |x| grammar[x][:id] } if v[:children]
    end
=end
    i = inverted_grammar
    g = i[node_class_id]
    raise "bad grammar" if g[:name].split(':').last != name or name != 'Root'

    begin
      confirm tree, i
      tree
    rescue GrammarTreeError => e
      s = "#{tree.class_def.name}, tree: #{tree.id}, #{e}"
      puts s
    rescue ModifiedTreeError => e
      puts e
    end

  end

end

# class Root < Node
#   def to_a
#     a = super
#     if a.size == 0
#       [ name, 'id', "node-#{id}", [] ]
#     else
#       a
#     end
#   end
# 
#   def tree_init(kit, tree)
#   end
# 
#   # list_name is a List node that represents a transcript/segmentation
#   # audio_name is the name of Audio node that is grandchild of list_name that holds the timestamps
#   def tree_init_from_segmentation(kit, tree, segmentation, list_name, audio_name, text_name=nil, speaker_name=nil)
#     task_id = kit.task_id
#     Kit.transaction do
#       list = children[list_name]
#       n = segmentation.audios.count - list.children.count # because list could be size 0 or 1
#       tree.add_new_nodes list, $creator_id, task_id, n
#       segmentation.run_over_audios do |i, audio, text, speaker|
#         list.fnbp("#{i}.#{audio_name}").change_value( { 'docid' => audio.parent_id, 'beg' => audio.btime, 'end' => audio.etime } )
#         list.fnbp("#{i}.#{text_name}").change_value_value text if text_name
#         list.fnbp("#{i}.#{speaker_name}").change_value_value speaker if speaker_name
#       end
#     end
#   end
# 
#   def convert_list(list, node_list, cc=nil)
#     @xml2node ||= {}
#     return if list.count == 0
#     #node_list = fnbp node_path
#     c = list.count
#     c -= 1 if node_list.children.count == 1
#     if cc
#       tree.add_new_nodes node_list, @user_id, @task_id, cc
#       node_list.children.last(cc).zip(list).each do |node, x|
#         @xml2node[x[:id]] = node
#         yield node, x
#       end
#     else
#       tree.add_new_nodes node_list, @user_id, @task_id, c
#       node_list.children.zip(list).each do |node, x|
#         @xml2node[x[:id]] = node
#         yield node, x
#       end
#     end
#   end
# 
#   def get_xml_list(element, selector)
#     element.css(selector).to_a.select { |x| yield x }
#   end
# 
#   def embedded_list(xml, selector, a)
#     xml.css(selector).each do |x|
#       #hash[x[:id]] = [ xml[:id], x ] #[:noun_type],
#       a << x
#     end
#   end
#   def xml2text(x)
#     b, l = x[:offset].to_i, x[:length].to_i
#     {
#       'docid' => x[:source],
#       'beg' => b,
#       'end' => b + l - 1,
#       'text' => x.text
#     }
#   end
#   def xml_map(xml, selector, hash)
#     xml.css(selector).each do |x|
#       hash[x[:id]] = x
#     end
#   end
# 
# end
# 
# class ModifiedTreeError < StandardError; end
# class GrammarTreeError < StandardError
#   attr_reader :message, :tree, :node
#   def initialize(message:, tree:, node:)
#     @message = message
#     @tree = tree
#     @node = node
#   end
#   def to_s
#     message.to_s
#   end
# end
