class Kit < ActiveRecord::Base
  # attr_accessible :meta, :user_id, :task_id, :kit_type_id, :uid, :state, :source, :broken_comment, :tree_id
  # attr_accessible :kit_batch_id, :not_user_id, :time_spent
  belongs_to :tree, optional: true
  belongs_to :user, optional: true
  belongs_to :task, optional: true
  belongs_to :kit_type, :class_name => 'KitType', optional: true
  belongs_to :kit_batch, optional: true
  belongs_to :not_user, :class_name => 'User', optional: true
  has_many :kit_stats
  has_many :kit_values
  has_many :kit_states
  delegate :nodes, :to => :tree, :prefix => true
  delegate :name, :to => :user, :prefix => true

  # serialize :meta, Hash
  serialize :source, Hash

  scope :assigned_by_task, lambda { |t| where( :state => 'assigned', :task_id => t ) }
  scope :unassigned_by_task, lambda { |t| where( :state => 'unassigned', :task_id => t ) }
  scope :unassigned_by_task_and_user, lambda { |t, u| where( :state => 'unassigned', :task_id => t, :user_id => u ) }
  scope :find_by_task, lambda { |task_id| where :task_id => task_id }

  # attr_accessor :source_type, :source_uid

  def editor
    meta['editor']
  end
  def editor=(arg)
    meta['editor'] = arg
  end

  @@counter = "0" * 16

  def meta
    @meta ||= {}
    @meta
  end

  [ :js, :source_transform, :unmapped_infoboxes, :root, :type,
    :workflow_id, :read_only, :parent, :task_user_id, :quality_control, :update_root, :view,
    :namestring, :es_kit, :existing_slots, :refdoc, :review, :lang, :slot, :query, :speaker,
    :empty_list, :coref_groups, :bootstrap_mode ].each do |sym|
    eval "def #{sym}; meta['#{sym}']; end;"
    eval "def #{sym}=(x); meta['#{sym}'] = x; end;"
  end



  after_save :goto_state

  def goto_state
    last = kit_states.last
    if last.nil? or last.state != state
      KitState.create(kit_id: id, state: state)
      task.workflow.after_done self if state == 'done' and kit_states.where(state: :done).count == 1
    end
  end

  def to_segmentation
    if source['type'] == 'audio'
      tree.tree.to_segmentation source['id']
    elsif source['parent'].class == Hash and source['parent']['type'] == 'audio'
      tree.tree.to_segmentation source['parent']['id']
    else
      raise 'bad source for segmentation'
    end
  end

  def kbptype
    meta['type']
  end

  def kbptype=(type)
    meta['type'] = type
  end

  def assign_id
    uid = ("%x" % Time.now.to_i) + @@counter.succ!
    while Kit.find_by_uid(uid)
      uid = ("%x" % Time.now.to_i) + @@counter.succ!
    end
    uid
  end

  def requeue
    Kit.transaction do
      reload
      if state == 'unassigned'
        update( uid: assign_id )
      end
    end
  end

  def initialize(*args)
    super
    self.uid = assign_id
  end

  def self.from_hash(h)
    kit = Kit.new
    case h['type']
    when /(person|gpe|org)/
      kit.kbptype = $1
      kit.fields_from_hash h, [ :namestring, :es_kit, :existing_slots, :refdoc, :unmapped_infoboxes, :slot, :query ]
      kit
    end

    kit.from_hash h unless kit.class == Kit

    #hack for kbp assessment
    kit.fields_from_hash h, [ :entity_slot, :slot, :query  ] if h['task_id'] == 75

    kit.id = h['_id']

    kit.fields_from_hash h, [ :tree, :state, :kit_type_id, :js, :root, :task_id, :user_id, :broken_comment,
                              :empty_list, :coref_groups, :type, :source_transform, :bootstrap_mode  ]

    #adding support for document display in legacy tools that used docid for the source
    if h.include? 'docid'
      kit.source = { 'type' => 'document', 'transform' => false, 'id' => h['docid'], 'media' => 'text' }
    else
      kit.source = h['source']
    end
    kit
  end

    # change to to to_interchange?
    def to_hash(mongo=false, depth='shallow', test=false)
      # return { refresh: true }
      h = {}
      h['_id'] = uid unless uid.nil?
      if tree_id
        if mongo
          h['tree'] = tree.uid
          if h['tree'].class == String and h['tree'].length == 0
            h.delete 'tree'
          end
        else
          root = tree.tree
          if root.children.keys.join(',') == 'SegmentList' and user_id == 1
            # json = { messages: [ { node: '0', message: 'correct', value: root.node_class_id } ] }.to_json
            # j = AnnotationJournal.create(user_id: user_id, task_id: task_id, kit_id: id, tree_id: tree_id, json: json, grammar: tree.class_def.inverted_grammar.to_yaml)
            # return { refresh: true }
          end
          h['tree'] = root.to_client_hash
          h['last_iid'] = tree.last_iid.to_i
          class_def = tree.class_def
          nc = NodeClass.where(name: "#{class_def.name}:#{uid}").first
          if nc
            nc.constraints['edit'] ||= {}
            nc.constraints['edit']['inverted_grammar'] ||= class_def.inverted_grammar
            nc.save
            h['edit'] = nc.constraints['edit']
          end
          h['inverted_grammar'] = class_def.inverted_grammar
          h['constraints'] = class_def.constraints if tree.respond_to? 'class_def'
          h['node_classes'] = {}
          class_def.node_classes.each do |nc|
            h['node_classes'][nc.id] = {}
            h['node_classes'][nc.id]['name'] = nc.name
            h['node_classes'][nc.id]['value'] = nc.value
            # raise StyleConnectionError, "missing style? node_type.id: #{nc.id}, node_type.name: #{nc.name}" if nc.style_id.nil?
            # h['node_classes'][nc.id]['tag'] = nc.style.tag
          end
        end
      end

      if depth == 'deep'
        #when a source exists, get the content and the metadata from the uget server with access to that content
        case source
        when Hash
          case source['type']
          when 'multi_post'
            file = LDC::Resources::WebMultiPost.find_by_uid(source['uid']).raw_text
            media = source['media'] ? source['media'] : 'normal'
            source.merge! LDCI::Document.new(source['id'], file, source['transform'], media).get_hash
            source['type'] = source[:type] = 'multi_post'
          when 'document'
            file = LDCI.uget( { :uid =>  source['id'], :type => source['type'], :level => 1 }.to_json )['string']
            media = source['media'] ? source['media'] : 'normal'
            source.merge! LDCI::Document.new(source['id'], file, source['transform'], media).get_hash
          when 'conversation'
            begin
              file = LDCI.uget( { :id =>  source['id'], :type => source['type'], :transform_message_content => source['transform'] }.to_json )
              source.merge! file
            rescue JSON::ParserError
              puts "Failed to parse JSON returned from uget for input: #{h['source']}"
            end
          end
        end
      end


      # h['source'] = {
      #   'id' => KitValue.where(kit_id: self.id, key: 'source_uid').first.value,
      #   # 'transform' => source['transform'], #"false",
      #   # 'media' => source['media'], #'text',
      #   'type' => KitValue.where(kit_id: self.id, key: 'source_type').first.value
      # }
      s = if source[:uid]

        Source.where(uid: source[:uid]).first
      elsif source[:id]
        Source.where(id: source[:id]).first
      else
        nil
      end
      h['source'] = if s
        { uid: s.uid, id: s.uid }
      elsif source_uid
        { uid: source_uid, id: source_uid }
      else
        {}
      end
      h['filename'] = source[:filename] if source[:filename]
      

      atts = [ :js, :source_transform, :kit_type_id, :broken_comment, :task_id, :root, :workflow_id, :read_only, :parent,
               :task_user_id, :quality_control, :state, :view, :meta, :done_comment ]

      h['type'] = case kbptype
                  when /(person|org|gpe)/
                    atts.concat [ :namestring, :es_kit, :existing_slots, :refdoc, :unmapped_infoboxes ]
                    kbptype
                  end
      atts.concat [ :empty_list, :coref_groups, :user_id ] # :update_root, :kit_type, :lang, :review
      h.delete 'type' if h['type'].nil?
      atts.concat [ :slot, :query ] if task_id == 75
      atts << :bootstrap_mode
      atts.each do |sym|
        eval "h['#{sym}'] = #{sym} unless #{sym}.nil?\n"

#        :query, :source, :bootstrap_mode ].each do |sym|
      end
      ann = Annotation.where(kit_id: id).last
      h['last_annotation_time'] = ann ? ann.created_at.to_i * 1000 : false
      h['task_preferences'] = task_preferences_hash
      h['data_set_id'] = task.data_set_id
      h['kit_id'] = id
      h
    end

    def transcript(all_nodes)
      t = tree.create_tree_sql2(all_nodes).to_client_hash
      {
        kit_uid: uid,
        # segments: (tree ? transcript_segments(tree) : []),
        # sections: (tree ? transcript_sections(tree): [])
        segments: transcript_segments(t),
        sections: transcript_sections(t)
      }
    end

    def transcript_segments(tree)
      tree['SegmentList']['children'].map { |x|
        {
          docid: x['Segment']['value'][:docid],
          beg: x['Segment']['value'][:beg],
          end: x['Segment']['value'][:end],
          text: (x['Transcription']['value'][:value] or ''),
          speaker: (x['Speaker']['value'][:value] or '')
        }
      }
    end
    
    def transcript_sections(tree)
      return [] if tree['SectionList'].nil?
      tree['SectionList']['children'].map { |x|
        {
          section: x['Section']['value'][:value],
          beg_seg: x['BegSeg']['value'][:value],
          end_seg: x['EndSeg']['value'][:value]
        }
      }
    end
    
    def task_preference_settings
      task.preference_settings_for_user(user)
    end

    def task_preferences_hash
      task_preference_settings.map do |setting|
        [ setting.preference_type_name, setting.value ]
      end.to_h
    end
    
  def fields_from_hash(h, fields)
    h.each_key do |attr|
      raise RuntimeError, "Hash key #{attr} is not a string" if attr != attr.to_s
    end
    fields.each do |sym|
      eval "self.#{sym} = h['#{sym}']"
    end
    self
  end

  def reset
    tree_oid = nil
    @tree = nil
  end

  def blocked_for_user_id?(user_id)
    KitUser.where( kit_id: id, user_id: user_id ).count > 0
  end

  def create_tree(task_user)
    root = kit_type.new_root self, task_user
    update( tree_id: root.tree_id )
  end

  def create_tree2(task_user:, source_kit:)
    source_kit_id = source_kit.id
    source_kit_ids = []
    while source_kit_id
      if source_kit_id.in? source_kit_ids # shouldn't be circular, but just in case
        source_kit_id = nil
      else
        source_kit_ids << source_kit_id
        source_kit_id = Kit.where(id: source_kit_id).first&.orig_id
      end
    end
    ids = Annotation.where(kit_id: source_kit_ids).pluck(:transaction_id)
    j = AnnotationJournal.where(id: ids).order(:id)
    root = kit_type.new_root2 kit: self, task_user: task_user, journals: j
    update( tree_id: root.tree_id )
    KitValue.create(kit_id: id, key: :source_kit, value: source_kit.id)
  end

end
