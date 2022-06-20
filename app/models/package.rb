class Package < ApplicationRecord
  has_many :kit_type_packages, dependent: :destroy
  has_many :kit_types, through: :kit_type_packages

  validates :name, presence: true
  validates :version, presence: true
  validates :name, uniqueness: { scope: :version }
end
