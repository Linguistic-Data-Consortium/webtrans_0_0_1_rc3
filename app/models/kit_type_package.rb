class KitTypePackage < ApplicationRecord
  belongs_to :kit_type
  belongs_to :package
  validates :kit_type_id, presence: true
  validates :package_id, presence: true

  delegate :name, to: :kit_type, prefix: true
  delegate :name, to: :package, prefix: true
end
