class CollectionsController < ApplicationController

  before_action :authenticate, :except => [:is_email_enrolled, :is_phone_number_enrolled]
  before_action :lead_annotator_user, :except => [:is_email_enrolled, :is_phone_number_enrolled, :show]
  before_action :admin_user, :only => [:destroy]

  # include CollectionsHelper

  #lists all collections, has a modal dialog which takes over functionality for the new action
  def index
    @title = 'All Collections'
    @collections = Collection.all
    @collection = Collection.new
    @projects_for_select = Project.sorted.map { |p| [p.name, p.id] }
    @collection_types_for_select = CollectionType.all.map { |p| [p.name, p.id] }
    @groups_for_select = Group.sorted.map { |g| [g.name, g.id] }
  end

  #new action is handled within the index page
  def new
    redirect_to collections_path
  end

  #action to actually create a new collection
  def create
    @collection = Collection.new collection_params

    if @collection.save
      flash[:success] = "Created #{ @collection.name } collection for #{ @collection.project_name }"
      redirect_to collection_path(@collection)
    else
      flash[:error] = @collection.errors.full_messages.join ', '
      redirect_back
    end

  end

  #edit action is handled within the show page
  def edit
    collection = Collection.find params[:id]
    redirect_to collection_path(collection)
  end

  #generic update action for each of the fields
  def update
    @collection = Collection.find params[:id]

    #figures out which parameter(s) have changed and sets that parameters value, and assigns its specific save success message
    messages = []
    if !collection_params[:meta]
      params[:collection].each do |k, v|
         @collection.send("#{k}=", v)
         messages.push save_messages(k, v)
      end
    else
      @collection.meta = {}
      pairs = collection_params[:meta].split(" ")
      pairs.each {|x| y=x.split(":"); @collection.meta[y[0]]=y[1]}
    end
    @collection.save ? flash[:success] = messages.join(',') : flash[:error] = @collection.errors.full_messages.join(', ')
    redirect_back
  end

  #action to actually delete a collection, restricted to system admins
  def destroy
    Collection.find(params[:id]).destroy
    redirect_back
  end

  #action to show an existing collection
  def show
    collection_id = params[:id]
    collection_id = Collection.where(name: 'ImageDescription').first.id
    e = Enrollment.where(collection_id: collection_id, user_id: current_user.id).first
    respond_to do |format|
      format.json do
        render :json => { enrollment_id: (e ? e.id : nil) }
      end
    end
    # @collection = Collection.find params[:id]
    # @instructions = params[:instructions]
    # if not @instructions
    #   redirect_to(root_path) unless @collection.is_user_in_manager_group?(current_user.id) or lead_annotator?
    # end
    #
    # @title = @collection.name
    # @enrollments = @collection.enrollments
    # @collection_languages = @collection.collection_languages
    # langs = Language.all
    # @lang_ref_names = langs.map { |l| l.ref_name }
    # @lang_ids = langs.map { |l| l.id }
    # @collection_language = CollectionLanguage.new( :collection_id => @collection.id )
    # @projects_for_select = Project.sorted.map { |p| [p.name, p.id] }
    # @start_date = @collection.start ? @collection.start.to_date : ''
    # @end_date = @collection.end ? @collection.end.to_date : ''
    # @groups_for_select = Group.sorted.map { |g| [g.name, g.id] }
    #
    #
    # enrollment = @collection.enrollments.by_user(current_user.id).first
    # #use the user-requested language if defined, otherwise default to the one defined in the enrollment
    # @language = params[:language]
    # if not @language
    #   if enrollment
    #     @language = enrollment.meta.has_key?(:language_screened) ? enrollment.meta[:language_screened] : enrollment.meta[:language_selected]
    #   else
    #     @language = 'english'
    #   end
    # end
    # if @language
    #   I18n.locale = {'english' => :en, 'chinese' => :cn, 'egyptian arabic' => :ar, 'egyptian_arabic' => :ar}[@language]
    # end
  end

  #action that checks whether an email address is enrolled in a collection
  def is_email_enrolled
    collection = Collection.find params[:id]
    respond_to do |format|
      format.js do
        render :json => {:email_exists => collection.is_email_enrolled?(params[:email], current_user)}
      end
    end
  end

  #action that checks whether an phone number address is enrolled in a collection
  def is_phone_number_enrolled
    collection = Collection.find params[:id]
    respond_to do |format|
      format.js do
        render :json => {:phone_number_exists => collection.is_phone_number_enrolled?(params[:phone_number], current_user)}
      end
    end
  end

  #action that adds a news entry to the meta[:news] array
  def add_news_entry
    collection = Collection.find params[:id]
    news_entry = {:time => Time.now.to_date, :content => params[:entry_content]}
    collection.meta[:news] = Array.new unless collection.meta[:news]
    collection.meta[:news].unshift(news_entry)
    collection.save

    respond_to do |format|
      format.js do
        render :json => {:html => render_to_string(:partial => '/collections/show/news_entry', :locals => {:news_entry => news_entry, :i => 0})}
      end
    end
  end

  #action that removes a news entry from the meta[:news] array
  def remove_news_entry
    collection = Collection.find params[:id]
    if collection.meta[:news]
      collection.meta[:news].delete_at(params[:remove_index].to_i)
      collection.save!
    end

    respond_to do |format|
      format.js do
        render :json => {}
      end
    end
  end

  # action to show ad-hoc/generic cts enrollment view for the collection
  def new_ad_hoc_cts_enrollment
    @collection = Collection.find(params[:id])
    @languages = @collection.languages.order(:ref_name)
  end

  # action to create ad-hoc/generic cts enrollment
  def create_ad_hoc_cts_enrollment
    collection = Collection.find(params[:collection])
    language = Language.find(params[:language])
    email = params[:email]

    # can (or should) we lookup email addresses directly from PiiProfile table?
    # pii = PiiProfile.by_email

    # user = User.find params[:user_id]
    user = create_ad_hoc_cts_user(collection.id, email)

    new_pin = collection.next_pin

    enrollment = Enrollment.create(
                                   user_id: user.id,
                                   collection_id: collection.id,
                                   pin: new_pin,
                                   enrolled_at: Time.now,
                                   :meta => {
                                        language_screened: language.ref_name
                                     }
                                   )

    participant = LdcDb::Lui::User.user_collection_enroll(
                                                          user.id,
                                                          collection.id,
                                                          true
                                                          )

    # maybe eventually claque attr is an option?
    participant.claque = true
    participant.save

    redirect_to enrollment_path(enrollment), :flash => {:success => "#{user.name} (#{email}) has been successfully enrolled in #{collection.name}"}

  end

  def list
    respond_to do |format|
      format.tsv do
        if pii?
          send_data "one\ttwo\tthree", :filename => 'test.tsv', :type => 'text/tab-separated-values'
        else
          flash[:error] = "you can't access other users' profiles"
          redirect_to root_path
        end
      end
    end
  end

  private

  def collection_params
    params.require(:collection).permit(:name, :enrollment_open , :start, :end, :meta, :project_id, :external_name, :collection_type_id)
  end

  # create a new user for purposes of CTS enrollment
  def create_ad_hoc_cts_user(collection_id, email)
    random_password = SecureRandom.base64
    user = User.new
    user.password = random_password
    user.password_confirmation = random_password
    user.name = "#{Collection.find(collection_id).external_name.split(" ").first}#{SecureRandom.hex(4)}User#{user.id}"
    user.login_time = Time.now
    user.pii_session = Time.now
    user.save! :validate => false

    #save the users email address in the pii profiles table
    pii_profile = user.pii_reader ? user.pii_reader.to_pii_profile : PiiProfile.new(:user_id => user.id)
    pii_profile.id = nil
    pii_profile.email = email
    pii_profile.save!

    user
  end

  #this function verifies that the user is in the manager_group
  def manager_user
    @collection = Collection.find params[:id]
    redirect_to(root_path) unless @collection.is_user_in_manager_group?(current_user.id) or lead_annotator?
  end

end
