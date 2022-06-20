class Researcher < ApplicationRecord
  validates :name, :presence => true
  belongs_to :project
  has_one_attached :image
end
