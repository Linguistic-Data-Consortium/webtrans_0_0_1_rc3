class WorkflowFind < Workflow

  def kits_available?(task_user)
    true
  end

  def work_assign(task_user)
    data_set = task_user.task.data_set
    if data_set.id == 2 # 16k image description audio
      c = Kit.where(task_id: task_user.task_id, user_id: task_user.user_id, state: [ :assigned, :unassigned ]).count
      if c > 0
        assign_kit task_user, :orderly
      else
        create_more_kits task_user, data_set
      end
    else
      raise "bad data set"
    end
  end

  def create_more_kits(task_user, data_set)
    # x = Kit.connection.execute(query).to_a.map { |x| x.values.first }
    x = data_set.files.pluck(:blob_id)
    x = ActiveStorage::Attachment.where(blob_id: x, record_type: 'Source').pluck(:record_id)
    x = Source.where(id: x).pluck(:uid)
    y = Kit.where(task_id: task_user.task_id).pluck(:source_uid)
    (x - y).first(10).each do |uid|
      kt = task_user.task.kit_type
      kit = Kit.new
      kit.task_id = task_user.task_id
      kit.kit_type_id = kt.id
      kit.state = 'unassigned'
      kit.source = { uid: uid }
      kit.source_uid = uid
      kit.save!
    end
    assign_kit task_user, :orderly
  end

  def query
    "  select
  distinct sub2.source_id
from
(
select
(case name when 'Recording' then split_part(v, ',', 2) end)::int source_id
from
(
select
nodes.name,
node_values.value as v
from tasks
join kits on kits.task_id = tasks.id
join nodes on nodes.tree_id = kits.tree_id
join node_values on node_values.id = nodes.node_value_id
where tasks.name in ('Image Description', 'Image Description Distributed')
and kits.state = 'done'
and nodes.level = 3
) sub1
) sub2
where sub2.source_id is not null
    "
  end
end
