class WorkflowBucketUser < WorkflowBucket
  
  # override, available kits based on user
  def count_available_kits
    Kit.where(task_id: @task_user.task_id, user_id: @task_user.user_id, state: [ :unassigned ]).count
  end

  # override, used sources based on user
  def source_uids_already_used
    source_uids_already_used_by_user
  end

  # override to add user
  def create_default_kit
    kit = @task_user.task.create_default_kit
    kit.user_id = @task_user.user_id
    kit
  end

end
