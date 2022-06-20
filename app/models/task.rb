# == Schema Information
#
# Table name: tasks
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  project_id             :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  node_class_id          :integer
#  workflow_id            :integer
#  help                   :text
#  help_video             :string(255)
#  per_person_kit_limit   :integer
#  kit_type_id            :integer
#  check_count            :integer
#  lock_user_id           :integer
#  token_counting_method  :text
#  status                 :string           limit 255, default 'active'
#  language_id            :integer
#  task_type_id           :integer
#  deadline               :datetime
#  cref_id                :integer
#  fund_id                :integer
#  game_variant_id        :bigint
#  meta                   :text
#  data_set_id            :integer

class Task < ActiveRecord::Base
  # attr_accessible :name, :workflow_id, :help, :kit_type_id, :per_person_kit_limit, :check_count, :lock_user_id

  validates( :name, :presence => true, :uniqueness => { :case_sensitive => false })
  serialize :token_counting_method, Hash
  serialize :meta, Hash
  has_many :task_users, :dependent => :destroy
  has_many :users, :through => :task_users
  has_many :compensations
  has_many :preference_types
  belongs_to :data_set, optional: true

  belongs_to :project
  belongs_to :workflow
  belongs_to :kit_type
  belongs_to :game_variant, optional: true
  belongs_to :data_set, optional: true

  has_many :pipes, :class_name => 'Pipes::TaskPipe', :foreign_key => :in_task_id
  has_many :audits, :class_name => 'Telco::Audit', :foreign_key => :task_id
  has_many :kits

  delegate :name, :users, :to => :project, :prefix => true
  delegate :name, :user_states, :to => :workflow, :prefix => true
  delegate :composite_name, :meta, :to => :kit_type, :prefix => true


  def self.recent
    order("created_at DESC limit 200")
  end

  #returns whether a user is a member of the task
  def member?(user)
    task_users.find_by_user_id(user.id)
  end

  #function that returns whether a user is admin of the task
  def admin?(user)
    tuser = find_task_user(user.id)
    !tuser.nil? ? tuser.admin? : false
  end

  #returns the task user object for a user
  def find_task_user(user_id)
    task_users.find_by_user_id(user_id)
  end

  #function that allows the deleting of a user from a task
  def delete_user(user)
    users.delete user
  end

  def name_with_project
    "#{id} - #{project.name} - #{name}"
  end

  #returns a list of all the users not in the task but in the project
  def other_users_in_project
    userids = userid_hash
    not_in_task = Array.new
    project_users.each do |user|
      not_in_task << user if !userids.include?(user.id)
    end
    not_in_task
  end

  #hash of user ids to assist with users not in task creation, allowing for faster lookups
  def userid_hash
    userids = Hash.new
    users.each do |user|
      userids[user.id] = user.id
    end
    userids
  end

  #this gets all the floating kits associated with a task (any kits that are in the assigned state, but no user has them assigned)
  def floating_kits
    floating = Array.new
    Kit.assigned_by_task(id).each do |kit|
      taskuser = TaskUser.kit_taskuser(kit.uid).first
      if !taskuser || !User.exists?(taskuser.user_id)
        floating << kit
      end
    end
    floating
  end

  #for kit types like audit2 where the available kits require a complex method to determine
  def available_kits
    kit_type.respond_to?('available_kits') ? kit_type.available_kits(id) : nil
  end

  #this returns whether there are kits available to work on
  def kits_available?
    avail = false
    if !available_kits.nil?
      avail = true if available_kits.count > 0
    elsif workflow.class == Workflows::OnTheFly
      avail = true
    else
      avail = true if unassigned_kits.count > 0
    end
    avail
  end

  #this returns whether the count of available kits
  def available_kit_count
    avail = 0
    if !available_kits.nil?
      avail = available_kits.count
    else
      avail = unassigned_kits.count
    end
    avail
  end

  #this returns the unassigned kits for the task
  def unassigned_kits
    Kit.unassigned_by_task(id)
  end

  def preference_settings_for_user(u)
    preference_types.map do |ptype|
      PreferenceSetting.where(preference_type: ptype, user: u).first_or_create
    end
  end

  def create_default_kit
    kit = Kit.new
    kit.task_id = id
    kit.kit_type_id = kit_type_id
    kit.state = 'unassigned'
    kit.save!
    kit
  end

  def use_default_doc(kit)
    docid = meta['docid']
    if docid
      # km = KitValue.where(kit_id: @kit.id, key: :source_uid).first_or_create
      # km.update(value: docid) if km.value.nil?
      kit.source = { uid: docid, id: docid, type: 'document' }
      kit.source_uid = docid
      kit.save!
    end
  end

  def create_default_kit_with_default_doc
    kit = create_default_kit
    use_default_doc kit
    kit
  end
  
end
