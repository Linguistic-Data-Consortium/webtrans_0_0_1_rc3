class AccountActivationsController < ApplicationController

  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in user
      flash[:success] = "Account activated!"
      @collection = Collection.where(name: 'ImageDescription').first
      if @collection
        @enrollment = Enrollment.where(collection_id: @collection.id, user_id: user.id).first
        if @enrollment
          redirect_to '/image_description'
        else
          redirect_to user
        end
      else
        redirect_to user
      end
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end

end
