class WorkflowNeuro < Workflow

  def kits_available?(task_user)
    true
  end

  def new_kits_available?(task_user)
    true
  end

  def work_assign(task_user)
    e = enroll_if_necessary task_user
    data_set = task_user.task.data_set
    if true
      if Kit.where(task_id: task_user.task_id, state: [ :unassigned ]).count == 0
        create_more_kits task_user, data_set
      end
      assign_kit task_user, :orderly
    else
      raise "bad data set"
    end
  end

  def create_more_kits(task_user, data_set)
    ids = Source.where(id: [5..28]).pluck(:id).sort
    # ids = (789..789).to_a if Rails.env.development?
    # ids = (46..69).to_a if ENV['APP_NAME'] == 'languagearc'
    # id = ids.first
    ids.shuffle.each do |id|
      kit = Kit.new
      kit.task_id = task_user.task_id
      kit.kit_type_id = task_user.task.kit_type_id
      kit.state = 'unassigned'
      kit.source = { id: id }
      # kit.source_uid = uid
      kit.save!
    end
  end

  def kit_source_helper(kit, source, manifest)
    manifest[:url] = manifest.delete(:urls).values.first
    manifest[:urls] = {}
    ids = (1..4).to_a
    # ids = (509..512).to_a if Rails.env.development?
    Source.where(id: ids).each do |source|
       manifest[:urls][source.uid] = source
    end
  end
    

end
