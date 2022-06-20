class PreferenceType < ApplicationRecord
  has_many :preference_settings, :dependent => :destroy
  belongs_to :task
  
  # values should always return a string, never null
  def values
    super || ""
  end
end
