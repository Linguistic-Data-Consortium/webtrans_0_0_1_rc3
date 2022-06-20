require 'ostruct'
class AnnotationJournal < ActiveRecord::Base

  after_create :create_annotations

  def create_annotations
    anns = nil
    transaction do
      last_ann = Annotation.where(tree_id: tree_id).last
      # last_ann = Ann.where(tree_id: kit_id).last if last_ann.nil?
      last_ann = OpenStruct.new(id: nil, last_iid: -1) if last_ann.nil? # or tree_id.nil?
      anns = generate_annotations.map do |ann|
        ann.parent_id = last_ann.id
        # ann.tree_id = kit_id if tree_id.nil?
        case ann.message
        when 'new', 'add'
          ann.last_iid += last_ann.last_iid
        when 'change', 'delete'
          if ann.iid.nil?
            ann.iid = last_ann.last_iid + ann.last_iid
          end
          ann.last_iid = last_ann.last_iid
        when 'correct'
          ann.last_iid = last_ann.last_iid + 2
        else
          ann.last_iid = last_ann.last_iid
        end
        ann.save!
        last_ann = ann
      end
      update(processed: true)
    end
    anns.each { |x| x.apply }
  end

  def generate_annotations
    # kit = Kit.find kit_id
    # g = YAML.load grammar
    g = Tree.find(tree_id).class_def.inverted_grammar
    ncmap = {}
    g.each do |k, v|
      ncmap[v[:name].split(':').last] = k
    end
    hash = JSON.parse(json)
    last_children = nil
    hash['messages'].map do |m|
      node = m['node']
      message = m['message']
      iid = nil
      last_iid = nil
      case node
      when String
        iid = node.to_i
      when Fixnum
        iid = node
      end
      case message
      when 'new', 'add', 'correct'
        case message
        when 'new'
          first = ncmap['Root']
        when 'add', 'correct'
          # nde = Node.where(tree_id: tree_id, iid: node).pluck(:node_class_id).first
          # nde = Nd.where(tree_id: tree_id, iid: iid).pluck(:node_class_id).first if nde.nil?
          nde = m['value'] if m['value']
          raise "node not found: tree_id #{tree_id}, node #{node}, iid #{iid}"  if nde.nil?
          # value = g[nde.node_class_id][:children].map { |x| "#{x}:#{g[x]}" }.join(',')
          first = g[nde][:children].first
        end
        last_children = [ first ] + g[first][:children]
        last_children = g[nde][:children] if message == 'correct'
        value = { 'value' => last_children.map { |x| "#{x}:#{g[x][:level]}" } }
        last_iid = last_children.length
      when 'change'
        value = m['value']
      else # includes delete, done, etc.
        value = { 'value' => m['value'] }
      end
      Annotation.new(
        transaction_id: id,
        user_id: user_id,
        task_id: task_id,
        kit_id: kit_id,
        tree_id: tree_id,
        message: message,
        iid: iid,
        last_iid: last_iid,
        node_value: NodeValue.new_value(value)
      )
    end
  end

end
