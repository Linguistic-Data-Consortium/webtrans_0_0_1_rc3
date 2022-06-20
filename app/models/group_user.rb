# == Schema Information
#
# Table name: group_users
#
#  id         :integer          not null, primary key
#  group_id   :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class GroupUser < ActiveRecord::Base
  # attr_accessible :group_id, :user_id
  belongs_to :group
  belongs_to :user
  validates :group_id, :presence => true
  validates :user_id, :presence => true
  
  delegate :name, :to => :user, :prefix => true
  delegate :name, :to => :group, :prefix => true
  
  scope :by_user, lambda{ |user_id| where(:user_id => user_id) }
end
