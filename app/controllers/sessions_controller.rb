class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :create

  def new
  end

  def confirmation
    @confirmation = true
  end

  def confirm
    user = User.find_by(name: params[:session][:name])
    if user && user.authenticate(params[:session][:password])
      if user.activated?
        user.update(confirmed_at: Time.now)
        respond_to do |format|
          format.html do
            redirect_back_or user
          end
          format.json do
            render json: { user: user.id, csrf: form_authenticity_token }
          end
        end
      else
        message = 'Account not activated.  '
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = 'Invalid username/email combination'
      render 'confirmation'
    end
  end

  def create
    user = User.find_by(name: params[:session][:name])
    if user&.authenticate(params[:session][:password])
      if user.activated?
        log_in user
        # params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        remember user
        respond_to do |format|
          format.html do
            # redirect_back(fallback_location: user)
            redirect_to user
          end
          format.json do
            render json: { user: user.id, csrf: form_authenticity_token }
          end
        end
      else
        message = 'Account not activated.  '
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = 'Invalid username/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  def destroy2
    log_out if logged_in?
    redirect_to root_url
  end

end
