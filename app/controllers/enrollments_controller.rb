class EnrollmentsController < ApplicationController

  before_action :authenticate
  # last change thomas made
  #before_action :lead_annotator_user, :except => [:show, :destroy, :withdrawn]
  #before_action :correct_user, :only => [:show]
  before_action :self_or_support_user, :only => [:index, :new, :edit, :update, :show, :withdrawn]
  before_action :self_or_admin_user, :only => [:destroy]

  def index
    @title = 'All enrollments'
    respond_to do |format|
      format.html
      format.json {
        if params[:json_format] == 'datatable'
          render json: EnrollmentsDatatable.new(view_context)
        elsif params[:collection_id]
          render json: Enrollment.includes(:user).where(collection_id: params[:collection_id]).map { |x| x.meta['user_name'] = x.user.name; x }
        else
          render json: Enrollment.all
        end
      }
    end
  end

  def new
  end

  def create
    p = params.permit(:collection_id, :fname, :lname, :street, :apt, :city, :state, :zip, :country, :email, :telephone, :skype, :sex, :year)
    @enrollment = Enrollment.new user_id: current_user.id, state: :active, task_state: :active
    if p[:collection_id] == '9'
      @enrollment.collection_id = 9
      @enrollment.task_state = 'active'
      email = p[:email] && p[:email].length > 0 ? p[:email] : current_user.pii_reader.email
      pii = PiiProfile.new(
        user_id: current_user.id,
        fname: p[:fname],
        lname: p[:lname],
        street: p[:street],
        apt: p[:apt],
        city: p[:city],
        state: p[:state],
        zip_code: p[:zip],
        country: p[:country],
        contact_phone: p[:telephone],
        email: email,
        skype: p[:skype]
      )
      demo = DemographicProfile.new(
        user_id: current_user.id,
        gender: p[:sex],
        year_of_birth: p[:year]
      )
    end
    # @enrollment.meta.merge! p
    respond_to do |format|
      format.json do
        saved = false
        Enrollment.transaction do
          @enrollment.save!
          pii.save! if pii
          demo.save! if demo
          saved = true
        end
        if saved
          render json: { status: 'saved' }
        else
          render json: { status: 'failed' }
        end
      end
    end
  end

  def edit
  end

  def update
    @enrollment = Enrollment.find params[:id]
    if @enrollment.collection_id == 9 and params[:task_state] == 'active' and IncomingFile.where(collection_id: 9, user_id: @enrollment.user_id, message: 'full').count > 10
      render json: { message: 'select allow_more_calls' }
    else
      if @enrollment.update(task_state: params[:task_state])
        if params[:allow_more_calls]
          @enrollment.meta["allow_more_calls"] = params[:allow_more_calls].to_i
          @enrollment.save!
        end
        # head :ok
        render json: { message: 'ok' }
      end
    end
  end

  def update_demographics
    @enrollment = Enrollment.find params[:id]
    @demo = DemographicProfile.where(user_id: @enrollment.user_id).first_or_create
    demo = params[:demographic_profile]
    @enrollment.meta[:school] = demo[:school]
    @enrollment.save!
    @demo.year_of_birth = demo[:age].to_i
    @demo.gender = demo[:gender]
    @demo.save!
    render json: { message: 'ok' }
  end

  def destroy
    @enrollment = Enrollment.find params[:id]
    @enrollment.withdrawn = true
    @enrollment.meta[:withdraw_reason] = params[:withdraw_reason]
    @enrollment.save!

    #send the confirmation email for withdrawal
    begin
      UserMailer.withdraw_from_collection(@enrollment)
    rescue Net::SMTPFatalError => e
      flash[:error] = e.to_s
    end

    redirect_to withdrawn_enrollment_path(@enrollment)
  end

  def withdrawn
    @enrollment = Enrollment.find params[:id]
  end

  def show
    #if this enrollment is incomplete, redirect the user to the root path
    redirect_to root_path, :flash => {:info => "This action is not permitted"} if @enrollment.incomplete

    #if the enrollment is withdrawn, redirect to the withdrawn path
    redirect_to withdrawn_enrollment_path(@enrollment) if @enrollment.withdrawn

    @participant = @enrollment.participant
    @collection = @enrollment.collection

    @demographics = @enrollment.user_current_demographics
    collection_name_camelcase = @collection.name.downcase.camelcase

    begin
      #call collection specific show page functionality based on a commonly defined method in the helper for that collection,
      #checks if method exists before calling
      my_helper = "#{collection_name_camelcase}sHelper".constantize
      @collection_vars = my_helper::initialize_show_page(@enrollment, current_user) if my_helper.respond_to? 'initialize_show_page'

      #retrieve a collection specific show page title, if such a title is defined
      @title = my_helper::show_page_title if my_helper.respond_to? 'show_page_title'
    rescue NameError => e
      #do nothing if helper is not defined
      #puts "initialize_show_page raised #{e.class}, #{e.message}, #{e.backtrace}"
      # backtrace seems unnecessary
      puts "initialize_show_page raised #{e.class}, #{e.message}"
    end
    @bolt_p2s_show = I18n.t 'bolt_p2s.show'
    @bolt_p2s_messages = I18n.t 'bolt_p2s.messages'
    @messages_edit = @bolt_p2s_messages[:edit]
    @save_button = @bolt_p2s_messages[:edit_modal][:save_button]
    respond_to do |format|
      format.html
      format.json do
        render json: @enrollment
      end
    end
  end

  def toggle_participant_active
    @participant = Enrollment.find(params[:id]).participant

    @participant.update(:active => params[:active])

    respond_to do |format|
      format.json { render :json => @message}
    end
  end
  
  private

  def enrollments_params # not used in this controller
    params.require(:enrollment).permit(:user_id, :collection_id, :meta, :pin, :enrolled_at, :incomplete, :state, :allow_more_calls)
  end
  
  #this before filter makes sure people can't see each other's enrollment info, unless they are lead annotators or in the collection manager group
  def self_or_support_user
    if params[:group_name] and params[:group_name] != 'true'
      count = GroupUser.where(group_id: Group.where(name: params[:group_name]).pluck(:id), user_id: current_user.id).count
    else
      count = 0
    end
    if params[:id]
      @enrollment = Enrollment.find params[:id]
      collection = @enrollment.collection
      redirect_to root_path unless @enrollment.user == current_user || lead_annotator? || collection.is_user_in_manager_group?(current_user.id) || admin? || count == 1
    else
      collection = Collection.find params[:collection_id]
      redirect_to root_path unless lead_annotator? || collection.is_user_in_manager_group?(current_user.id) || admin? || count == 1
    end
  end

  def self_or_admin_user
     @enrollment = Enrollment.find params[:id]
     collection = @enrollment.collection
     redirect_to root_path unless @enrollment.user == current_user || admin?
  end
  #this before filter makes sure people can't see each other's enrollment info, unless they are lead annotators or in the collection manager group
  # def correct_user
  #   @enrollment = Enrollment.find params[:id]
  #   collection = @enrollment.collection
  #   redirect_to root_path unless @enrollment.user == current_user || lead_annotator? || collection.is_user_in_manager_group?(current_user.id)
  # end

end
