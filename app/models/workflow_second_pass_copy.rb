class WorkflowSecondPassCopy < WorkflowSecondPass

  def create_more_kits
    loop_over_kits_to_do do |source_kit|
      kit = task.create_default_kit
      kit.orig_id = source_kit.id
      share_source_and_block_first_user kit: kit, source_kit: source_kit, status: 'qc'
      kit.create_tree2 task_user: @task_user, source_kit: source_kit
    end
  end

  def create_dual(source_kit)
    kit = source_kit.task.create_default_kit
    make_dual_and_block_first_user kit: kit , source_kit: source_kit, status: 'dual'
    # here we need the source kit of the source kit
    sk = Kit.find KitValue.where(kit_id: source_kit.id, key: :source_kit).first.value
    KitUser.create(kit_id: kit.id, user_id: sk.user_id, status: 'dualqc')
    # build tree from original, not the copy which got 2p
    kit.create_tree2 task_user: @task_user, source_kit: sk
  end

end
