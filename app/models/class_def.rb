class ClassDef < ActiveRecord::Base
  serialize :constraints, Hash

  validates( :name, :presence => true,
             :uniqueness => { :case_sensitive => false },
             :length => { :maximum => 50 } )

  #has_many :tasks
  has_many :node_classes

  scope :sorted, -> { order('name ASC') }

  def sorted_node_classes
    node_classes.order 'name ASC'
  end

  def node_class_names
    names = Hash.new
    node_classes.each do |nc|
      names[nc.name_without_prefix] = ''
    end
    names
  end

  def get_root_node_class
    get_node_class "#{name}:Root"
  end

  def get_node_class(name)
    node_classes.find_by_name name
  end

  def get_node_class_from_path(path, node_class=nil)
    return nil if path.nil?
    node_class = get_root_node_class if node_class.nil?
    return node_class if path == ''
    path.split('.').each do |name|
      if node_class.types.include? 'List'
        node_class = get_node_class node_class.children.split('.')[1]
      else
        node_class = get_node_class node_class.get_children_map[name]
      end
      return nil if node_class.nil?
    end
    node_class
  end

  def new_root
    tree = Tree.new
    tree.class_def_id = id
    tree.version = version
    tree.assign_id
    tree.save!
    # tree.new_root user_id, task_id
    tree
  end

  def constraints
    obj = nil #UserDefinedObject.find_by_name "#{name}Constraints"
    obj.nil? ? {} : JSON.parse(obj.object)
  end

  # not used currently
  def g(nc, ncs)
    if nc.children and nc.children.length > 0
      c = nc.children.split(',').map { |x| n = x.split('.')[1]; ncs.select { |x| x.name == n }.first }
      { nc.name => c.map { |x| g(x, ncs) } }
    else
      nc.name
    end
  end

  # not used currently
  def groot(root, ncs)
    [ g(root, ncs) ]
  end
 
  # create a grammar hash by recursing down through node classes
  def get_grammar_helper(nc, ncs, hash={})
    hash[nc.name] = { id: nc.id, parent_id: nc.parent_id }
    hash[nc.name][:auto_add] = nc.constraints['auto_add'] if nc.constraints['auto_add']
    hash[nc.name][:keys] = nc.constraints['keys'] if nc.constraints['keys']
    if nc.children and nc.children.length > 0
      c = nc.children.split(',').map { |x| n = x.split('.')[1]; ncs.select { |x| x.name == n }.first }.compact
      hash[nc.name][:children] = c.map { |x| x.name }
      c.each { |x| get_grammar_helper(x, ncs, hash) }
    end
    hash
  end

  def grammar
    @grammar ||= get_grammar
  end

  def inverted_grammar
    @inverted_grammar ||= get_inverted_grammar
  end

  # create a grammar hash
  def get_grammar
    ncs = node_classes
    root = ncs.select { |x| x.name == "#{name}:Root" }.first
    get_grammar_helper root, ncs
  end

  def get_inverted_grammar
    inverse = {}
    pids = {}
    NodeClass.where(name: %w[ Root List Node ]).map { |x| pids[x.name] = x.id }
    grammar.each do |k, v|
      level =
        case v[:parent_id]
        when pids['List']
          1
        when pids['Root'], pids['Node']
          2
        else
          3
        end
      inverse[grammar[k][:id]] = { name: k, level: level }
      inverse[grammar[k][:id]][:children] = v[:children].map { |x| grammar[x][:id] } if v[:children]
      inverse[grammar[k][:id]][:auto_add] = v[:auto_add] if v[:auto_add]
      inverse[grammar[k][:id]][:keys] = v[:keys] if v[:keys]
    end
    inverse
  end

  # def get_grammar2
  #   g = get_grammar
  #   gg = {}
  #   r = g.keys.select { |x| x =~ /:Root\z/ }.first
  #   gg = { r => {} }
  #   get_grammar2r g, gg[r], r
  #   gg
  # end

  # def get_grammar2r(g, gg, k)
  #   cc = g[k][:children]
  #   return if cc.nil?
  #   cc.each do |c|
  #     gg[c] = {}
  #     get_grammar2r g, gg[c], c
  #   end
  # end

  # print grammar as yaml
  def print_grammar
    grammar = get_grammar
    puts grammar.to_yaml
  end

  # check all trees with this namespace for grammar conformity
  def confirm
    # grammar = get_grammar
    Tree.where(class_def_id: id).each do |tree|
      #next if tree.nodes.count < 100
      #next unless tree.id == 455666
      tree.confirm
    end
  end

  def confirm_select
    # grammar = get_grammar
    Tree.where(class_def_id: id).map do |tree|
      #next if tree.nodes.count < 100
      #next unless tree.id == 455666
      tree.confirm
    end
  end

  # def set_parent_id
  #   LDCI::Tree.where(class_def_id: id).each do |tree|
  #     tree.set_parent_id
  #   end
  # end

  def confirm_by_task(task_id)
    grammar = get_grammar
    #LDCI::Tree.where(id: LDCI::Kit.where(task_id: task_id).pluck(:tree_id)).each do |tree|
    Tree.where(id: Kit.where(task_id: task_id).pluck(:tree_id)).each do |tree|
      #next if tree.nodes.count < 100
      tree.confirm grammar
    end
  end

  def show_create_views
    @views = {}
    create_views_helper
    @views.each do |k, v|
      puts v
    end
    nil
  end
  def show_create_tables
    @views = {}
    create_tables_helper
    @views.each do |k, v|
      puts v
    end
    nil
  end

  def grammar_table_namesx
    grammar_table_names.map { |x| x + 'x' }
  end

  def rootncid
    @rootncidv ||= NodeClass.find_by_name('Root').id
  end

  def nodencid
    @nodencidv ||= NodeClass.find_by_name('Node').id
  end

  def listncid
    @listncidv ||= NodeClass.find_by_name('List').id
  end

  def grammar_table_names
    grammar.map do |k, v|
      if v[:children] and (v[:parent_id] == rootncid or v[:parent_id] == listncid)
        k.sub(':','')
      end
    end.compact
  end

  def create_views_helper
    grammar.each do |k,v|
      if v[:children] and v[:parent_id] == rootncid
        doroot(k, v)
      end
      if v[:children] and v[:parent_id] == listncid
        dolist(k, v)
      end
    end
    do_kits
  end

  def create_tables_helper
    grammar.each do |k,v|
      if v[:children] and v[:parent_id] == rootncid
        doroot_t(k, v)
      end
      if v[:children] and v[:parent_id] == listncid
        dolist_t(k, v)
      end
    end
  end

  def insert_tree_into_tables_helper
    grammar.each do |k,v|
      if v[:children] and v[:parent_id] == rootncid
        doroot_i(k, v)
      end
      if v[:children] and v[:parent_id] == listncid
        dolist_i(k, v)
      end
    end
  end

  def create_views
    @views = {}
    create_views_helper
    @views.each do |k, v|
      #puts db.fetch("select * from  #{k};").to_a
      #vv = v.sub(/create.+/,'')
      puts k
      self.class.connection.execute v
    end
    update(views_created: true)
    nil
    # puts db.fetch("SHOW FULL TABLES IN rails_production  WHERE TABLE_TYPE LIKE 'VIEW';").to_a
  end

  def create_tables
    @views = {}
    create_tables_helper
    @views.each do |k, v|
      #puts db.fetch("select * from  #{k};").to_a
      #vv = v.sub(/create.+/,'')
      puts k
      self.class.connection.execute v
    end
    update(views_created: true)
    nil
    # puts db.fetch("SHOW FULL TABLES IN rails_production  WHERE TABLE_TYPE LIKE 'VIEW';").to_a
  end

  def insert_tree_connect
    if defined?(Rails) and Rails.env == 'production'
      $sequel_rails
    else
      Sequel.connect LDCI::CONFIG[:rails_development]
    end
  end

  def show_select_for_insert_trees_into_tables
    @views = {}
    insert_tree_into_tables_helper
    @views.each do |k, v|
      puts k
      puts
      v.each do |x|
        puts x
      end
    end
    nil
  end

  def checksums_for_treex(tree_id:, tables:, db:)
    insert_trees_into_tables(tree_ids: [ tree_id ], force: true, verbose: false)
    checksums_for_tree(tree_id: tree_id, tables: tables.map { |x| x + 'x' }, db: db)
  end

  def checksums_for_tree(tree_id:, tables:, db:)
    tables.map do |table|
      Digest::MD5.hexdigest(db.fetch("select * from #{table} where tree_id = #{tree_id}").to_a.to_s)
    end
  end

  def insert_trees_into_tables(tree_ids:, verbose: true, force: false, x: true, show: false)
    raise "you can't call this function" unless force
    verbose = true if show
    @views = {}
    insert_tree_into_tables_helper
    # db = Sequel.connect LDCI::CONFIG[:rails_readonly]
    # dbb = Sequel.connect LDCI::CONFIG[:rails_development]
    dbb = db = insert_tree_connect
    tree_ids.each do |tree_id|
      puts "TREE #{tree_id}" if verbose
      @views.each do |kk, v|
        k = kk
        k += 'x' if x
        puts k if verbose
        q = "delete from #{k} where tree_id = #{tree_id}"
        if show
          puts q
        else
          dbb.fetch(q).to_a
        end
        db.fetch(v.first.gsub('TREE_ID', tree_id.to_s)) do |row|
          if show
            puts "insert #{row}"
          else
            dbb[k.to_sym].insert row
          end
        end
        v[1..-1].each do |vv|
          db.fetch(vv.gsub('TREE_ID', tree_id.to_s)) do |row|
            update_hash, where_hash = update_statement(row)
            if show
              puts "update #{update_hash} where #{where_hash}"
            else
              dbb[k.to_sym].where(where_hash).update(update_hash)
            end
          end
        end
      end
    end
    nil
  end

  def insert_statement(h)
    "insert into TABLE (#{h.keys.join(',')}) values (#{h.values.join(',')})"
  end

  def update_statement(h)
    update_hash = {}
    where_hash = { tree_id: h[:tree_id] }
    if h[:iid]
      h.keys[3..-1].each do |k|
        update_hash[k] = h[k]
      end
      kk = h.keys[2]
      where_hash[kk] = h[kk]
    else
      h.keys[1..-1].each do |k|
        update_hash[k] = h[k]
      end
    end
    [ update_hash, where_hash ]
  end

  def show_drop_tables
    @views = {}
    create_tables_helper
    @views.each do |k, v|
      #puts db.fetch("select * from  #{k};").to_a
      #vv = v.sub(/create.+/,'')
      next if k =~ /_index\z/
      # puts k
      v =~ /create table (\w+)/
      puts "drop view if exists #$1"
      puts "drop table if exists #$1"
    end
    nil
    # puts db.fetch("SHOW FULL TABLES IN rails_production  WHERE TABLE_TYPE LIKE 'VIEW';").to_a
  end

  def drop_tables
    @views = {}
    create_tables_helper
    @views.each do |k, v|
      #puts db.fetch("select * from  #{k};").to_a
      #vv = v.sub(/create.+/,'')
      next if k =~ /_index\z/
      # puts k
      v =~ /create table "(\w+)"/
      # self.class.connection.execute "drop view if exists #$1"
      self.class.connection.execute "drop table if exists \"#$1\""
    end
    update(views_created: false)
    nil
    # puts db.fetch("SHOW FULL TABLES IN rails_production  WHERE TABLE_TYPE LIKE 'VIEW';").to_a
  end

  def do_kits
    query = nil
    case name
    when 'VieFullEntity'
      query = query_hash
      query['select'] << "kv1.value as source_uid"
      query['select'] << "kv2.value as 1p_uid"
      query['select'] << "kv3.value as 2p_uid"
      query['select'] << "kv4.value as dual_uid"
      query['from'] = 'kits'
      query['join'] << 'left kit_values as kv1 on kv1.kit_id = kits.id and kv1.key = "source_uid"'
      query['join'] << 'left kit_values as kv2 on kv2.kit_id = kits.id and kv2.key = "1p_uid"'
      query['join'] << 'left kit_values as kv3 on kv3.kit_id = kits.id and kv3.key = "2p_uid"'
      query['join'] << 'left kit_values as kv4 on kv4.kit_id = kits.id and kv4.key = "dual_uid"'
    end
    if query
      kit_type_ids = KitTypes::KitType.all.select { |x| x.meta['root'] == "#{name}:Root" }.map { |x| x.id.to_s }.join(', ')
      query['select'] = [ "kits.id", "uid", "state", "user_id", "task_id", "tree_id" ] + query['select']
      query['where'] << "kit_type_id in (#{kit_type_ids})"
      view_name = name + 'Kits'
      @views[view_name] =  "create or replace view #{view_name} as\n" + query_string_and(query).gsub('join left','left join')
    end
  end

  def create_views_old
    @views = {}
    grammar.each do |k,v|
      if v[:children] and v[:parent_id] == rootncid
        dorootold(k, v)
      end
      if v[:children] and v[:parent_id] == listncid
        dolistold(k, v)
      end
    end
    @views.each do |k, v|
      #puts db.fetch("select * from  #{k};").to_a
      #vv = v.sub(/create.+/,'')
      puts k
      self.class.connection.execute v
    end
    nil
    # puts db.fetch("SHOW FULL TABLES IN rails_production  WHERE TABLE_TYPE LIKE 'VIEW';").to_a
  end

  def getx
    @namex ||= ''
  end

  def setx
    @namex = 'x'
  end

  def groot_name
    "#{name}Root#{getx}"
  end

  # class ClassDef; def groot_name; "#{name}Rootx"; end; def gview_name(pk); pk.sub(':','') + 'x'; end; end

  def doroot(pk, pv)
    dolistitem(pk, pv, nil, groot_name)
  end
  def doroot_t(pk, pv)
    dolistitem_t(pk, pv, nil, groot_name)
  end
  def doroot_i(pk, pv)
    dolistitem_i(pk, pv, nil, groot_name)
  end

  def dorootold(pk, pv)
    dolistitemold(pk, pv, nil, name)
  end

  def gview_name(pk)
    pk.sub(':','') + getx
  end

  def dolist(pk, pv)
    view_name = gview_name pk
    k = pv[:children][0]
    v = @grammar[k]
    if v[:children] and v[:parent_id] == nodencid
      dolistitem(k, v, pv[:id], view_name)
    end
  end
  def dolist_t(pk, pv)
    view_name = gview_name pk
    k = pv[:children][0]
    v = @grammar[k]
    if v[:children] and v[:parent_id] == nodencid
      dolistitem_t(k, v, pv[:id], view_name)
    end
  end
  def dolist_i(pk, pv)
    view_name = gview_name pk
    k = pv[:children][0]
    v = @grammar[k]
    if v[:children] and v[:parent_id] == nodencid
      dolistitem_i(k, v, pv[:id], view_name)
    end
  end

  def dolistold(pk, pv)
    view_name = pk.split(':').last
    k = pv[:children][0]
    v = @grammar[k]
    if v[:children] and v[:parent_id] == nodencid
      dolistitemold(k, v, pv[:id], view_name)
    end
  end

  def dolistitemold(k, v, ppncid, view_name)
    query = query_hash
    query['select'] << 'trees.id as tree_id'
    if ppncid
      query['select'] << 'pp.iid as iid'
      n = k.split(':').last
      query['select'] << "p.iid as #{n}_iid"
      query['join'] << "ndes as pp on pp.tree_id = trees.id and pp.node_class_id = #{ppncid}"
      query['join'] << "ndes as p on p.parent_id = pp.id and p.current = true"
    else
      query['join'] << "ndes as p on p.tree_id = trees.id and p.node_class_id = #{v[:id]}"
    end
    query['from'] = 'trees'
    #query['join'] << "ndes as p on p.tree_id = trees.id and p.current = true"
    query['where'] << "trees.class_def_id = #{id}"
    #      query['where'] << p.current = true
    #      query['where'] << p.current = true
    v[:children].each_with_index do |kkvv,i|
      kk, vv = kkvv
      n = kk.split(':').last
      query['select'] << "n#{i}.iid as #{n}_iid"
      query['join'] << "ndes as n#{i} on n#{i}.parent_id = p.id and n#{i}.node_class_id = #{@grammar[kk][:id]}"
      unless @grammar[kk][:parent_id] == 3
        query['select'] << "v#{i}.value as #{n}_value"
        query['join'] << "node_values as v#{i} on v#{i}.id = n#{i}.node_value_id"
      end
    end
    @views[view_name] =  "create or replace view #{view_name} as\n" + query_string_and(query)

  end

  def dolistitem(k, v, ppncid, view_name)
    query = query_hash
    # query['select'] << 'trees.id as tree_id'
    if ppncid
      query['select'] << 'pp.tree_id as tree_id'
      query['select'] << 'pp.iid as iid'
      n = k.split(':').last
      query['select'] << "p.iid as #{n}_iid"
      query['from'] = 'nds as pp'
      # query['join'] << "nds as pp on pp.tree_id = trees.id and pp.node_class_id = #{ppncid}"
      query['join'] << "nds as p on p.parent_id = pp.id and p.current = true"
      # query['where'] << "trees.class_def_id = #{id}"
      query['where'] << "pp.node_class_id = #{ppncid}"
    else
      query['select'] << 'p.tree_id as tree_id'
      query['from'] = 'nds as p'
      # query['join'] << "nds as p on p.tree_id = trees.id and p.node_class_id = #{v[:id]}"
      # query['where'] << "trees.class_def_id = #{id}"
      query['where'] << "p.node_class_id = #{v[:id]}"
    end
    #query['join'] << "nds as p on p.tree_id = trees.id and p.current = true"
    #      query['where'] << p.current = true
    #      query['where'] << p.current = true
    ncs = []
    v[:children].each_with_index do |kkvv,i|
      kk, vv = kkvv
      n = kk.split(':').last
      query['select'] << "n#{i}.iid as #{n}_iid"
      # query['join'] << "nds as n#{i} on n#{i}.parent_id = p.id and n#{i}.node_class_id = #{@grammar[kk][:id]}"
      # query['join'] << "(select parent_id, nde_value_id from nds where node_class_id = #{@grammar[kk][:id]}) as n#{i} on n#{i}.parent_id = p.id"
      query['join'] << "nodeclass#{@grammar[kk][:id]} as n#{i} on n#{i}.parent_id = p.id"
      ncs << @grammar[kk][:id]
      unless @grammar[kk][:parent_id] == 3
        if docid_only(kk)
          query['select'] << "v#{i}.docid as #{n}_docid"
        elsif @grammar[kk][:parent_id] == 2629
          query['select'] << "v#{i}.docid as #{n}_docid"
          query['select'] << "v#{i}.begr as #{n}_beg"
          query['select'] << "v#{i}.endr as #{n}_end"
          query['select'] << "v#{i}.play_head as #{n}_play_head"
        elsif @grammar[kk][:parent_id] == 5
          query['select'] << "v#{i}.docid as #{n}_docid"
          query['select'] << "v#{i}.begi as #{n}_beg"
          query['select'] << "v#{i}.endi as #{n}_end"
          query['select'] << "v#{i}.text as #{n}_text"
        elsif media_provenance(kk)
          query['select'] << "v#{i}.docid as #{n}_docid"
          query['select'] << "v#{i}.begi as #{n}_begi"
          query['select'] << "v#{i}.endi as #{n}_endi"
          query['select'] << "v#{i}.begr as #{n}_begr"
          query['select'] << "v#{i}.endr as #{n}_endr"
          query['select'] << "v#{i}.text as #{n}_text"
          query['select'] << "v#{i}.extra as #{n}_points"
          query['select'] << "v#{i}.value as #{n}_type"
        else
          query['select'] << "v#{i}.value as #{n}_value"
        end
        query['join'] << "nde_values as v#{i} on v#{i}.id = n#{i}.nde_value_id"
      end
    end
    ncs.each do |ncid|
      name = "nodeclass#{ncid}"
      @views[name] = "create or replace view #{name} as select parent_id, nde_value_id, iid from nds where node_class_id = #{ncid}"
    end
    @views[view_name] =  "create or replace view #{view_name} as\n" + query_string_and(query)

  end
  def dolistitem_t(k, v, ppncid, view_name)
    query = query_hash
    # query['select'] << 'trees.id as tree_id'
    if ppncid
      query['select'] << 'tree_id int'
      query['select'] << 'iid int'
      n = k.split(':').last
      query['select'] << "\"#{n}_iid\" int"
    else
      query['select'] << 'tree_id int'
    end
    ncs = []
    v[:children].each_with_index do |kkvv,i|
      kk, vv = kkvv
      n = kk.split(':').last
      query['select'] << "\"#{n}_iid\" int"
      ncs << @grammar[kk][:id]
      unless @grammar[kk][:parent_id] == 3
        if docid_only(kk)
          query['select'] << "\"#{n}_docid\" varchar(255)"
        elsif @grammar[kk][:parent_id] == 2629
          query['select'] << "\"#{n}_docid\" varchar(255)"
          query['select'] << "\"#{n}_beg\" numeric(12,6)"
          query['select'] << "\"#{n}_end\" numeric(12,6)"
          query['select'] << "\"#{n}_play_head\" numeric(10,3)"
        elsif @grammar[kk][:parent_id] == 5
          query['select'] << "\"#{n}_docid\" varchar(255)"
          query['select'] << "\"#{n}_beg\"integer"
          query['select'] << "\"#{n}_end\"integer"
          query['select'] << "\"#{n}_text\" text"
        elsif media_provenance(kk)
          query['select'] << "\"#{n}_docid\" varchar(255)"
          query['select'] << "\"#{n}_begr\" numeric(12,6)"
          query['select'] << "\"#{n}_endr\" numeric(12,6)"
          query['select'] << "\"#{n}_begi\" integer"
          query['select'] << "\"#{n}_endi\" integer"
          query['select'] << "\"#{n}_text\" text"
          query['select'] << "\"#{n}_points\" varchar(255)"
          query['select'] << "\"#{n}_type\" varchar(255)"
        else
          query['select'] << "\"#{n}_value\" text"
        end
      end
    end
    @views[view_name] =  "create table \"#{view_name}\" (\n" + t_query_helper(query) + "\n)\n"
    index_name = "#{view_name}_index"
    @views[index_name] =  "create index \"#{index_name}\" on \"#{view_name}\" (tree_id" + ( view_name =~ /Root\w?\z/ ? '' : ', iid' ) + ')'
  end

  def dolistitem_i(k, v, ppncid, view_name)
    query = query_hash
    # query['select'] << 'trees.id as tree_id'
    if ppncid
      query['select'] << 'pp.tree_id as tree_id'
      query['select'] << 'pp.iid as iid'
      n = k.split(':').last
      query['select'] << "p.iid as #{n}_iid"
      query['from'] = 'nds as pp'
      # query['join'] << "nds as pp on pp.tree_id = trees.id and pp.node_class_id = #{ppncid}"
      query['join'] << "nds as p on p.parent_id = pp.id and p.current = true"
      # query['where'] << "trees.class_def_id = #{id}"
      query['where'] << "pp.tree_id = TREE_ID" << "pp.node_class_id = #{ppncid}"
    else
      query['select'] << 'p.tree_id as tree_id'
      query['from'] = 'nds as p'
      # query['join'] << "nds as p on p.tree_id = trees.id and p.node_class_id = #{v[:id]}"
      # query['where'] << "trees.class_def_id = #{id}"
      query['where'] << "p.tree_id = TREE_ID" << "p.node_class_id = #{v[:id]}"
    end
    @views[view_name] = [ query_string_and(query) ]
    #query['join'] << "nds as p on p.tree_id = trees.id and p.current = true"
    #      query['where'] << p.current = true
    #      query['where'] << p.current = true
    v[:children].each_with_index do |kkvv,i|
      kk, vv = kkvv
      n = kk.split(':').last
      queryy = {}
      %w[ select from join where order ].each do |x|
        queryy[x] = query[x].dup
      end
      queryy['select'] << "n#{i}.iid as #{n}_iid"
      # queryy['join'] << "nds as n#{i} on n#{i}.parent_id = p.id and n#{i}.node_class_id = #{@grammar[kk][:id]}"
      queryy['join'] << "(select iid, parent_id, nde_value_id from nds where node_class_id = #{@grammar[kk][:id]}) as n#{i} on n#{i}.parent_id = p.id"
      # queryy['join'] << "nodeclass#{@grammar[kk][:id]} as n#{i} on n#{i}.parent_id = p.id"
      unless @grammar[kk][:parent_id] == 3
        if docid_only(kk)
          queryy['select'] << "v#{i}.docid as #{n}_docid"
        elsif @grammar[kk][:parent_id] == 2629
          queryy['select'] << "v#{i}.docid as #{n}_docid"
          queryy['select'] << "v#{i}.begr as #{n}_beg"
          queryy['select'] << "v#{i}.endr as #{n}_end"
          queryy['select'] << "v#{i}.play_head as #{n}_play_head"
        elsif @grammar[kk][:parent_id] == 5
          queryy['select'] << "v#{i}.docid as #{n}_docid"
          queryy['select'] << "v#{i}.begi as #{n}_beg"
          queryy['select'] << "v#{i}.endi as #{n}_end"
          queryy['select'] << "v#{i}.text as #{n}_text"
        elsif media_provenance(kk)
          queryy['select'] << "v#{i}.docid as #{n}_docid"
          queryy['select'] << "v#{i}.begi as #{n}_begi"
          queryy['select'] << "v#{i}.endi as #{n}_endi"
          queryy['select'] << "v#{i}.begr as #{n}_begr"
          queryy['select'] << "v#{i}.endr as #{n}_endr"
          queryy['select'] << "v#{i}.text as #{n}_text"
          # queryy['select'] << "v#{i}.extra as #{n}_points"
          queryy['select'] << "v#{i}.value as #{n}_type"
        else
          queryy['select'] << "v#{i}.value as #{n}_value"
        end
        queryy['join'] << "nde_values as v#{i} on v#{i}.id = n#{i}.nde_value_id"
      end
      @views[view_name] << query_string_and(queryy)
    end

  end

  def docid_only(k)
    @grammar[k][:parent_id] == 8156 or @grammar[k][:id] == 9375
  end

  def media_provenance(k)
    @media_provenance_ids ||= NodeClass.where('id > 9730').select { |x| x.constraints['classes'] =~ /MediaProvenance/ }.map { |x| x.id }
    @grammar[k][:id].in? @media_provenance_ids
  end

  def t_query_helper(query)
    query['select'].join(",\n")
  end

  def query_hash
    {
      'select' => [],
      'from' => '',
      'join' => [],
      'where' => [],
      'order' => []
    }
  end

  def query_string_and(q)
    "select\n" + q['select'].join(",\n") + "\n\n" +
      "from #{q['from']}\n\n" +
      ( q['join'].size > 0 ? q['join'].map { |x| "join #{x}" }.join("\n") + "\n\n" : '' ) +
      "where #{q['where'].join(' and ')}" + "\n\n" +
      ( q['order'].size > 0 ? "order by " + q['order'].join(',') + "\n" : '' )
  end

end
