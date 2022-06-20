class CollectedUrlsController < ApplicationController
  # Everything below this can be pasted directly into a new controller
  before_action :authenticate
  before_action :accept_all_params

  def new
    # Prefill with params (in case create failed)
    prefill = get_params
    if prefill.nil?
      prefill = {:user_id => session[:user_id]}
    else
      prefill[:user_id] = session[:user_id] 
    end
    # Prefill with specified fields from last entry
    if get_model.get_prefillwithmostrecent.length>0
      allinstances = get_model.where(user_id: session[:user_id])
      if allinstances.length>0
        lastinstance = allinstances.last
        for p in get_model.get_prefillwithmostrecent
          prefill[p] = lastinstance[p] if prefill[p].nil?
        end
      end
    end
    @instance = get_model.new prefill
    @user = @instance # For error messages
  end

  def create
    prefill = get_params
    prefill[:user_id] = session[:user_id]
    @instance = get_model.new get_params
    if @instance.save
      flash[:message] = "Report successfully created"
      redirect_to root_url
    else
      flash[:error] = @instance.errors.full_messages.join("; ")
      render 'new'
    end
  end

  def index
    redirect_to :action => 'new'
  end

  def get_public_fields
    respond_to do |format|
      format.json {
        render json: get_model.get_publicfields
      }
    end
  end

  private

  def accept_all_params
    params.permit!
  end

  def get_model
    controller_name.classify.constantize
  end

  def get_params
    puts "Controller: #{controller_name.classify.gsub(/(?<!^)([A-Z])/,'_\1').downcase}"
    params[controller_name.classify.gsub(/(?<!^)([A-Z])/,'_\1').downcase]
  end
end
