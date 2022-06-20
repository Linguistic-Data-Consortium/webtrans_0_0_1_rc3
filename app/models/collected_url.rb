class CollectedUrl < ApplicationRecord
  belongs_to :user

  validates :user_id, :presence => true, :format => { :with => /\A\d+\z/i, :message => "must be a valid numeric id"}
  validates :url, :presence => true, :format => { :with => /\A\s*https:\/\/bluejeans.com\/s\/.{5,}\s*\z/i, :message => "must be of format: https://bluejeans.com/s/xxxxx"}
  validates :inddid, :presence => true
  validates :coordinator, :presence => true
  validates :center, :presence => true
  validates :session_type, :presence => {:message => "- Battery cannot be empty"}, :format => {:with => /=>".+"/i, :message => "- Battery cannot be blank" }
  validates :when, :presence => {:message => ": you must give both a date and a time"}
  validate :new_public_fields_require_admin, on: :create

  before_save :set_tag
  before_save :set_when   # Need a special method to recouple date & time fields (see below)

  PREFILLWITHMOSTRECENT = ['inddid', 'coordinator', 'center']  # Prefill these fields with values from the latest entry
  TAG = "bluejeans"                                            # This will be added to the tag column of the table
  PUBLIC_FIELDS = [:center,:session_type]                      # Publicly accessible to new forms

  def self.get_prefillwithmostrecent 
    PREFILLWITHMOSTRECENT
  end

  def self.get_publicfields
    self.pluck(*PUBLIC_FIELDS).uniq
  end

  def new_public_fields_require_admin
    return true if user.admin?
    fields = PUBLIC_FIELDS.map{|f|self[f.to_s]}
    self.class.pluck(*PUBLIC_FIELDS).uniq.each do |fu|
      match = true
      fields.each_with_index{ |f,i| match = match && f==fu[i] }
      return true if match
    end
    PUBLIC_FIELDS.each{|f|
      errors.add(f, "can only be extended by admins")
    }
    return false
  end
  
  # DATE + TIME methods start here
  def starts_at_date=(date)
    @starts_at_date = date
    set_when
    date
  end
  def starts_at_time=(time)
    @starts_at_time = time
    set_when
    time
  end
  def starts_at_date
    self.when&.strftime('%m/%d/%Y')
  end
  def starts_at_time
    self.when&.strftime('%H:%M')
  end
  
  private
  def set_when
    unless @starts_at_date.blank? or @starts_at_time.blank?
      self.when = Time.zone.parse("#{@starts_at_date} #{@starts_at_time}")
    end
  end
  # DATE + TIME methods end here

  def set_tag
    self.tag = TAG
  end
end
