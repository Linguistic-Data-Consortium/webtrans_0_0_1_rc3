# == Schema Information
#
# Table name: collections
#
#  id               :integer          not null, primary key
#  project_id       :integer          not null
#  name             :string(255)      not null
#  start            :datetime
#  end              :datetime
#  enrollment_open  :boolean          default(FALSE)
#  user_data_fields :text
#  meta             :text
#  external_name    :string(255)
#  contact_email    :string(255)
#  manager_group_id :integer
#

class Collection < ActiveRecord::Base

  # attr_accessible :name, :enrollment_open , :start, :end, :meta, :project_id, :external_name, :collection_type_id

  serialize :meta, Hash


  belongs_to :project
  # belongs_to :collection_type
  belongs_to :manager_group, :class_name => 'Group', optional: true
  has_many :enrollments
  has_many :incoming_files
  has_many :users, :through => :enrollments
  has_many :conversations
  has_many :collection_languages, :dependent => :destroy
  has_many :languages, :through => :collection_languages

  delegate :name, :to => :project, :prefix => true

  scope :sorted, -> { order('name ASC') }
  delegate :complete, :complete_by_user, :to => :enrollments, :prefix => true
  delegate :name, :group_users, :to => :manager_group, :prefix => true

  validates( :name, :presence => true,
             :uniqueness => { :case_sensitive => false },
             :format => { :with => /\A[a-z][a-z0-9_]*\z/i, :message => "only accepts alphanumeric characters (a-z and 0-9) and underscores, also must start with a letter"} )

  #this function checks to see if a user_id is present in the collection management group
  def is_user_in_manager_group?(user_id)
    manager_group ? manager_group_group_users.by_user(user_id).first : nil
  end

  #this function takes a user id, checks the collection's enrollments, and returns whether the user is enrolled
  def is_user_enrolled?(user_id)
    enrollments.complete_by_user(user_id).count > 0
  end

  #this function takes an email address and returns whether that email address is enrolled in the collection
  def is_email_enrolled?(email_address, current_user)
    is_pii_field_enrolled(:email, email_address, current_user)
  end

  #this function takes a phone number and returns whether that contact phone is enrolled in the collection
  def is_phone_number_enrolled?(phone_number, current_user)
    is_pii_field_enrolled(:contact_phone, phone_number, current_user)
  end

  def get_withdrawn_conversation_uids
    enrollments.withdrawn.map{|e|e.user.conversations}.flatten.map{|c|c.uid}.uniq
  end

  # define here whether enrollments can be manually/generically created for
  # a given collection
  def accepts_ad_hoc_enrollments?
    begin
      if collection_type.name == 'cts'
        true
      else
        false
      end
    rescue
      false
    end
  end

  # generates the next pin for the collection, based on values in the
  # existing enrollments for the collection
  def next_pin
    last_enrollment = self.enrollments_complete.order('pin').last
    new_pin = last_enrollment && last_enrollment.pin ? last_enrollment.pin.succ : '0001'
    new_pin
  end

  def report0(current_user_id:)
    calls = incoming_files.where(user_id: current_user_id).pluck(:id)
    # this extra machinary is just to fix the time zone
    {
      header: header_helper,
      rows: report0_helper(calls)
    }
  end

  def report1
    calls = incoming_files.pluck(:id)
    {
      header: header_helper(true),
      rows: report0_helper(calls, true)
    }
  end

  def report2
    header = ['# enrolled', '# with 0 calls', '# with 1 OK call', '# with 2-9 OK calls', '# with 10 OK calls', '# with 11+ OK calls']
    counts = call_counts
    {
      header: header,
      rows: [ counts ]
    }
  end

  def template
    {
      'total' => 0,
      'skype' => { 'y' => 0, 'n' => 0 },
      'noise' => { 'noisy' => 0, 'notnoisy' => 0},
      'person' => { 'y' => 0, 'n' => 0 },
      'codes' => []
    }
  end

  def report4
    full = incoming_files.where(message: 'full')
    codes = full.pluck(:confirmation_code).compact
    promises = {}
    Promise.where(confirmation_code: codes).each do |p|
      promises[p.confirmation_code] = p
    end
    full_count = full.count
    all = {}
    full.each do |c|
      p = promises[c.confirmation_code]
      next if p.nil?
      all[p.user_id] ||= template
      all[p.user_id]['total'] += 1
      call = p.promise
      %w[ skype noise person ].each do |x|
        next if call[x].nil?
        all[p.user_id][x][call[x]] += 1
      end
      all[p.user_id]['codes'] << c.confirmation_code
    end
    counts = call_counts
    {
      header:
        [
          'Username',
          'User_id',
          'status',
          'enrollment_date',
          'first call date',
          'last call date',
          'calls',
          'skype_calls',
          'non_skype_calls',
          'noisy_calls',
          'non_noisy_calls',
          'new callees',
          '10 calls',
          '11 calls',
          '3 Skype calls',
          '5 noisy calls',
          '3 or more callees'
        ],
      rows: enrollments.includes(:user).map { |x|
        types = all[x.user_id] || template
        times = full.where(confirmation_code: types['codes']).pluck(:start_time).compact.sort
        [
          x.user.name,
          x.user_id,
          x.state,
          time_helper(x.created_at),
          time_helper(times.first),
          time_helper(times.last),
          types['total'],
          types['skype']['y'],
          types['skype']['n'],
          types['noise']['noisy'],
          types['noise']['notnoisy'],
          types['person']['n'],
          '?', #counts[4],
          '?', #counts[5],
          (types['skype']['y'] >= 3 ? 'Y' : 'N'),
          (types['noise']['noisy'] >= 5 ? 'Y' : 'N'),
          (types['person']['n'] >= 3 ? 'Y' : 'N')
        ]
      }
    }
  end


  private

  def call_counts
    counts = (0..5).to_a.map { 0 }
    counts[0] = enrollments.count
    counts[1] = counts[0]
    # calls = incoming_files.where(message: 'full').group(:user_id).count
    $sequel_rails.fetch(
      "select
      count(i.id) as c
      from promises p
      join incoming_files i on p.confirmation_code = i.confirmation_code
      where p.collection_id = #{id} and i.message = \"full\"
      group by p.user_id"
    ).each do |x|
      case x[:c]
      when 1
        counts[2] += 1
      when 2..9
        counts[3] += 1
      when 10
        counts[4] += 1
      else
        counts[5] += 1
      end
    end
    (2..5).to_a.each { |x| counts[1] -= counts[x] }
    counts
  end

  #generic function that returns whether an enrollment with a specific field/value pair exists
  def is_pii_field_enrolled(field, field_value, current_user)
    is_enrolled = false#assume false unless we find otherwise

    #cycle through all the enrollments for this collection
    enrollments.each do |enrollment|
      #update the pii session so we can actually retrieve the field to check in all cases
      e_user = enrollment.user
      if e_user#double check that enrollment has a user
        e_user.pii_session = Time.now
        e_user.save! :validate => false

        pii = enrollment.user_pii_reader

        #if the field value matches set is_enrolled to true and break from loop
        #also make sure current user is not with this enrollment, so we don't block same value saves
        if pii and field_value == pii.send(field) and current_user != enrollment.user
          is_enrolled = true
          break
        end
      end
    end
    is_enrolled
  end

  def header_helper(recruiter=false)
    header = (1..9).to_a.map { |i| I18n.t "cmn2.main.table4.s#{i}" }
    header += %w[ User Path ] if recruiter
    header
  end

  def report0_helper(calls, recruiter=false)
    text = text_helper
    $sequel_rails.fetch(
      "select
      p.name, p.created_at, p.confirmation_code, p.promise,
      i.message, i.start_time, i.duration, i.path,
      u.name as user_name
      from promises p
      join incoming_files i on p.confirmation_code = i.confirmation_code
      join users u on p.user_id = u.id
      where p.collection_id = #{id}"
    ).map do |x|
      # date = new Date()
      # dd = new Date(x.created_at)
      # time = Math.round((Date.now() - dd.getTime())/60000)
      status = case x[:name]
      when 'init'
        Time.now - 30.minutes >= x[:created_at] ? 10 : 11
      when 'in_progress'
        12
      when 'done'
        13
      end
      x[:message] = 'nul' if x[:message].nil?
      x[:message] = 'nul' if x[:message] == 'init'
      x[:message] = 'error' if x[:message] !~ /^(nul|full|short|bad_sad|sad_fail|chan_fail)$/
      meta = x[:promise] ? YAML.load(x[:promise]) : {}
      a = [
          x[:confirmation_code],
          I18n.t("cmn2.main.table4.s#{status}"),
          I18n.t("cmn2.main.table2.s#{meta['skype'] == 'y' ? 3 : 4}"),
          text[meta['phone']],
          text[meta['mic']],
          text[meta['noise']],
          time_helper(x[:start_time]),
          (x[:duration] ? x[:duration] : ''),
          I18n.t("cmn2.main.table4.#{x[:message]}")
      ]
      a << x[:user_name] << x[:path] if recruiter
      a
    end
  end
  def time_helper(x)
    return '' if x.nil?
    #DateTime.parse(x.localtime("+01:00").strftime("%d/%m/%Y %H:%M")).to_s
    x.localtime("+01:00").strftime("%d/%m/%Y %H:%M")
  end

  def text_helper
    text = {}
    b = [ %w[ y n ], %w[ computer mobile landline ], %w[ internal plugin wireless speakerphone ], %w[ noisy notnoisy ], %w[ y n ] ]
    c = %w[ skype phone mic noise person ]
    (1..5).to_a.zip(b, c).each do |d|
      i, aa, bb = d
      aa.each do |x|
        text[x] = I18n.t "cmn2.main.page5.s#{i}.#{x}"
      end
    end
    # %w[ ok_skype_y ok_skype_n ok_noise_noisy ok_noise_notnoisy ].each do |x|
    #   text[x] = @messages[x]
    text
  end

end
