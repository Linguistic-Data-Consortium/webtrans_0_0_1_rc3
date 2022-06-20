class GameVariant < ApplicationRecord
  belongs_to :game
  has_many :tasks
  
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  
  serialize :meta, Hash
end