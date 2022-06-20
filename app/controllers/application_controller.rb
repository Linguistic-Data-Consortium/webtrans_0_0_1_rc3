class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  before_action :set_paper_trail_whodunnit  
  #development uses better errors which would be blocked by this rescue
  if !Rails.env.development?
    rescue_from StandardError do |e|
      #write output to log
      current_path = File.expand_path('.') + '/'
      logger.debug "Rescued from a StandardError exception: #{e.to_s}"
      e.backtrace.each do |line|
        logger.debug line.sub(current_path, '')
      end
      
      #return error via ajax
      if params.keys.include? 'json'
        response = {:error => 'An error occurred while performing this action, please refresh the page and try this action again. If this issue persists, please report it to the LDC.'}
        response[:full_error] = {:message => e.to_s, :backtrace => e.backtrace} if admin?
        respond_to do |format|
          format.json do
            render :json => response
          end
        end
      #render exception page if non-ajax request
      else
        @e = e
        render 'layouts/exception'
      end
    end
  end

  def respondj
    respond_to do |format|
      format.json do
        render json: yield
      end
    end
  end

  def allow(only)
    if only == :admin and admin?
      yield
    elsif only == :project_manager and project_manager?
      yield
    elsif only == :own and @instance.user_id == current_user.id
      yield
    elsif only == :any
      yield
    else
      { error: 'Permission denied.' }
    end
  end
  
  def index_all(model:, only:)
    respondj do
      allow(only) do
        model.sorted.all.map(&:attributes)
      end
    end
  end

  def index_own(model:)
    respondj do
      model.sorted.where(user_id: current_user.id).map(&:attributes)
    end
  end

  def show_users(model:, params:, users:, only:)
    respondj do
      allow(only) do
        m = model.find(params[:id])
        a = m.attributes
        a[users[0]] = users[1].call(m) if users
        a
      end
    end
  end

  def createj(model:, params:, only:, own: false)
    respondj do
      allow(only) do
        instance = model.new params
        instance.user_id = current_user.id if own
        if instance.save
          instance.attributes
        else
          { error: instance.errors.full_messages }
        end
      end
    end
  end

  def updatej(model:, p:, params:, only:, own: false)
    respondj do
      instance = model.find(p[:id])
      @instance = instance
      allow(only) do
        if instance.update params
          instance.attributes
        else
          { error: instance.errors.full_messages }
        end
      end
    end
  end

  def destroyj(model:, params:, only:, own: false)
    respondj do
      instance = model.find(params[:id])
      @instance = instance
      allow(only) do
        instance.destroy
        { deleted: "#{model} #{instance.name or instance.id} has been deleted." }
      end
    end
  end

end
