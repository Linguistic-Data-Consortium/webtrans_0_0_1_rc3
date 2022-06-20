class Annotation < ActiveRecord::Base
  belongs_to :node_value
  def apply
    case message
    when 'new', 'add', 'correct'
      parent_id = Node.where( tree_id: tree_id, iid: iid ).pluck(:id).first
      children = node_value.value.split(',')
      puts "children: #{children}, #{node_value_id}"
      niid = last_iid - children.length
      children.each_with_index do |x, i|
        niid += 1
        if message == 'correct'
          next if i == 0
        end
        node_class_id, level = x.split(':').map(&:to_i)
        index =
          if i == 0
            if message == 'new'
              Node.where(node_class_id: node_class_id).count
            else
              Node.where(parent_id: parent_id).count
            end
          else
            i - 1
          end
        if message == 'correct'
          index = i
        end
        nd = Node.create(
          name: Annotation.get_node_name(node_class_id),
          parent_id: parent_id,
          index: index,
          iid: niid,
          user_id: user_id,
          task_id: task_id,
          level: level,
          tree_id: tree_id,
          node_class_id: node_class_id,
          node_value_id: 0,
          current: true
        )
        Tree.find(tree_id).update(last_iid: last_iid.to_s)
        parent_id = nd.id if i == 0
      end
    when 'change'
      Node.where( tree_id: tree_id, iid: iid ).update_all( node_value_id: node_value_id, user_id: user_id, task_id: task_id )
    when 'delete'
      Node.where( tree_id: tree_id, iid: iid ).update_all( current: false, user_id: user_id, task_id: task_id )
    end
  end

  def self.get_node_name(node_class_id)
    @@node_names ||= {}
    begin
      @@node_names[node_class_id] ||= NodeClass.find(node_class_id).name.split(':').last
    rescue => e
      nil
    end
  end

end
