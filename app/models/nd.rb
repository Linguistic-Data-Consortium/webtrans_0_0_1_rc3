class Nd < ActiveRecord::Base
  belongs_to :node_class, optional: true
  belongs_to :nde_value, optional: true
  belongs_to :parent, optional: true, class_name: 'Nd'
  include TreeableHelper
  attr_accessor :name
  attr_accessor :types, :css, :extra_classes, :horiz, :children, :child
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
    meta['child'] = child if child
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
    NdeValue.transaction do
      self.nde_value = NdeValue.new_value value
      save!
    end
  end

  def value
    @value ||= get_value
  end

  private

  def get_value
    if nde_value_id == 0
      { value: nil }
    elsif nde_value.btext
      {
        docid: nde_value.docid,
        beg: nde_value.begi,
        end: nde_value.endi,
        text: nde_value.btext,
        display_selector: nde_value.display_selector
      }
    elsif nde_value.begr
      {
        docid: nde_value.docid,
        beg: nde_value.begr.to_f,
        end: nde_value.endr.to_f,
        play_head: nde_value.play_head.to_f
      }
    else
      { value: nde_value.bvalue }
    end
  end

end
