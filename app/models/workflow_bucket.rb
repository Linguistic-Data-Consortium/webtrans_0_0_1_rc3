=begin

This Workflow creates kits based on the source media in  an S3 bucket.  It assigns
kits the same way as Orderly, but first creates kits if necessary.  While the Orderly
Workflow depends on a set of kits being created first, WorklowBucket treats a
bucket as a list of files and creates the kits as needed.  Since files can always
be added to a bucket, it's a dynamic list.  More details below.

=end

class WorkflowBucket < Workflow

  include AwsHelper

  # this sums up the workflow:  create kits if necessary, then assign in order
  def main
    create_more_kits_if_necessary
    assign_kit :orderly
  end

  # if there are no unassigned kits, create some more
  def create_more_kits_if_necessary
    create_more_kits if count_available_kits == 0
  end
  
  # create kits from bucket, excluding used items
  # limit number of created kits to reduce delay
  def create_more_kits
    create_kits_from_bucket excluding: source_uids_already_used, limit: 10
  end
    
  def create_kits_from_bucket(excluding:, limit:)
    x = keys_from_bucket bucket: bucket_name, excluding: excluding, limit: limit
    # x = [[ 'demo/CarrieFisher10s.wav', 'demo/CarrieFisher10s.wav' ]]
    # raise @task_user.inspect
    # raise x.to_s
    x.each do |uid, fn|
      kit = create_default_kit
      kit.source = { uid: uid, id: uid, filename: fn }
      kit.source_uid = uid
      kit.save!
    end
  end

  def create_default_kit
    @task_user.task.create_default_kit
  end

  def new_kits_available?(task_user)
    true
  end
    

end
