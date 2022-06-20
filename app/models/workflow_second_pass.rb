class WorkflowSecondPass < Workflow

  # creates kits that point to the same trees in another task
  # the idea is to go over the done kits in another task and modify them
  
  def main
    create_more_kits_if_necessary
    assign_kit :orderly
  end

  # if there are no available kits, create some more
  # available means unassigned and not blocked
  def create_more_kits_if_necessary
    create_more_kits if unassigned_not_blocked_kit_ids.count == 0
  end

  # kits "to do" means kits from the 1p without a kit in 2p yet
  # to do kits are the 1p done kits, excluding kits by the current user
  def kit_uids_to_do
    kit_uids_from_1p_done - kit_uids_from_1p_by_current_user - kit_uids_from_original_kits
  end

  def new_kits_available?(task_user)
    @task_user = task_user
    @task_id = @task_user.task_id
    @user_id = @task_user.user_id
    unassigned_not_blocked_kit_ids.count > 0 or kit_uids_to_do.count > 0
  end
  
  def create_more_kits
    loop_over_kits_to_do do |source_kit|
      kit = task.create_default_kit
      kit.tree_id = source_kit.tree_id
      kit.orig_id = source_kit.id
      share_source_and_block_first_user(kit: kit, source_kit: source_kit, status: status)
    end
  end

end
