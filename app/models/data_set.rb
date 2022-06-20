class DataSet < ApplicationRecord
  validates :name, presence: true, uniqueness: {case_sensitive: false }
  has_one_attached :spec
  has_one_attached :manifest
  has_many_attached :files
  has_many :tasks # so you can easily see which tasks are using this data set
  scope :sorted, -> { order('name ASC') }
end
