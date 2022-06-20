# == Schema Information
#
# Table name: enrollments
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :integer          not null
#  collection_id :integer          default(0), not null
#  enrolled_at   :datetime
#  meta          :text
#  pin           :string(255)
#  withdrawn     :boolean          default(FALSE)
#  incomplete    :boolean          default(FALSE)
#
class Enrollment < ActiveRecord::Base

  has_paper_trail

  # attr_accessible :user_id, :collection_id, :meta, :pin, :enrolled_at, :incomplete

  serialize :meta, Hash

  belongs_to :collection
  belongs_to :user

  delegate :name, :enrollments_complete, :external_name, :start, :to => :collection, :prefix => true
  delegate :name, :current_demographics, :current_language_names, :pii_reader, :current_email, :to => :user, :prefix => true

  scope :sorted, -> { order('email ASC') }
  scope :complete, -> { where(:incomplete => false) }
  scope :by_user, lambda{ |user_id| where(:user_id => user_id) }
  scope :complete_by_user, lambda{ |user_id| complete.by_user(user_id) }
  scope :withdrawn, -> { where(:withdrawn => true) }

  validates :collection_id, :uniqueness => {:scope=>:user_id}
  validates :user_id, :uniqueness => {:scope=>:collection_id}

  #this returns the ldc_db version of the enrollment
  def to_ldcdb
    return OpenStruct.new if Rails.env.development?
    LdcDb::Lui::Enrollment.find(id)
  end

  #this returns a ldc_db participant
  def participant
    self.to_ldcdb.participant
  end

  def self.report3(collection_id:)
    query = includes(:user).where(collection_id: collection_id)
    {
      header: [ 'User', 'Status' ],
      rows: query.map { |x|
        [
          x.user.name,
          [ x.id, x.task_state ]
        ]
      }
    }
  end

  def report6
    s1, s2, s3, s4, s5, s6, s7, s8 = (1..8).to_a.map { |x| I18n.t("cmn2.main.table2.s#{x}") }
    successful = IncomingFile.where(collection_id: collection_id, user_id: user_id, message: 'full')
    ok_skype_y = successful.where(message: 'full').select { |x| x.meta['skype'] == 'y' }.count
    ok_skype_n = successful.where(message: 'full').select { |x| x.meta['skype'] == 'n' }.count
    {
      title: s2,
      rows: [
        [ '', s3, s4 ],
        [ s5, 3, 8 ],
        [ s6, ok_skype_y, ok_skype_n ],
        [ s8, (3 - ok_skype_y), (8 - ok_skype_n) ]
      ]
    }
  end

  def report7
    s1, s2, s3, s4, s5, s6, s7 = (1..7).to_a.map { |x| I18n.t("cmn2.main.table3.s#{x}") }
    successful = IncomingFile.where(collection_id: collection_id, user_id: user_id, message: 'full')
    ok_noise_noisy = successful.where(message: 'full').select { |x| x.meta['noise'] == 'noisy' }.count
    ok_noise_notnoisy = successful.where(message: 'full').select { |x| x.meta['noise'] == 'notnoisy' }.count
    {
      title: s2,
      rows: [
        [ '', s2, s3 ],
        [ s4, 5, 6 ],
        [ s5, ok_noise_noisy, ok_noise_notnoisy ],
        [ s7, (5 - ok_noise_noisy), (6 - ok_noise_notnoisy) ]
      ]
    }
  end

end
