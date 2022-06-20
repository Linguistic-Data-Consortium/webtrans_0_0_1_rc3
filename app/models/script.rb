class Script < ApplicationRecord

  scope :sorted, -> { order('name ASC') }

  belongs_to :rgroup, class_name: 'Group', optional: true
  belongs_to :wgroup, class_name: 'Group', optional: true
  belongs_to :xgroup, class_name: 'Group', optional: true

end
