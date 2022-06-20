class Language < ApplicationRecord
  # TODO: add these relations
  # has_many :conversations
  # has_many :collection_languages, :dependent => :destroy
  # has_many :collections, :through => :collection_languages
  # has_many :task_type_users

  validates( :lang_scope, :presence => true)
  validates( :lang_type, :presence => true)
  validates( :ref_name, :presence => true)
  validates_inclusion_of( :custom, :in => [true, false])

  validates_length_of :iso_id, :is => 3
  validates_length_of :locale, :is => 2, :allow_nil => true
  validates_length_of :lang_scope, :is => 1
  validates_length_of :lang_type, :is => 1
  validates_length_of :ref_name, :maximum => 150
  validates_length_of :comment, :maximum => 150, :allow_nil => true

  validates_inclusion_of :lang_scope, :in => %w( I M S )
  validates_inclusion_of :lang_type, :in => %w( A C E H L S )

  scope :by_code, lambda{ |code| where(:iso_id => code) }
  scope :by_ref_name, lambda{ |ref_name| where(:ref_name => ref_name)}

end
