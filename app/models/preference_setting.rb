class PreferenceSetting < ApplicationRecord
  # attr_accessible :preference_type_id, :user_id, :value
  belongs_to :user
  belongs_to :preference_type
  
  delegate :name, :to => :preference_type, :prefix => true
  delegate :name, :to => :user, :prefix => true

  validates :user_id, :presence => true
  validates :preference_type_id, :presence => true, :uniqueness => {:scope => :user_id}
  # controller should use find_or_create to make settings, to avoid duplication
  #
  def values
    preference_type.values.split(/,\s*/)
  end

end
