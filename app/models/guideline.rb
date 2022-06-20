class UniqueCombination < ActiveModel::Validator
  def validate(record)
    if Guideline.where(name: record.name, url: record.url, version: record.version).length>0
      record.errors[:base] << "Found exact duplicate of guidelines"
    end
  end
end


class Guideline < ApplicationRecord
  validates :name, presence: true
  validates :url, presence: true#, uniqueness: {case_sensitive: false, message: "already associated with existing guidelines"}
  validates :version, presence: true

  validates_with UniqueCombination

  has_one_attached :file

end
  