class DemographicProfile < ActiveRecord::Base
    belongs_to :user, inverse_of: :profile
    has_paper_trail
  
    validates( :user, :presence => true, :uniqueness => true)
  
    validates( :gender, :allow_blank => true, length: { maximum: 12 })
    validates( :year_of_birth, :allow_nil => true,
               :numericality => { :greater_than_or_equal_to => 1890,
                 :only_integer => true},
               :length => {:is => 4})
    validates( :cities, :allow_blank => true, length: { maximum: 400 })
    validates( :languages_known, :allow_blank => true, length: { maximum: 400 })
  
  end
  
