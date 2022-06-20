class UserDefinedObjectsController < ApplicationController

  before_action :admin_user

  def index
    @title = 'All Objects'
    @objects = UserDefinedObject.all
    @object = UserDefinedObject.new
  end

  def create
    @object = UserDefinedObject.new user_defined_object_params

    if @object.save
      flash[:success] = "Created #{ @object.name }"
      redirect_to user_defined_object_path(@object)
    else
      flash[:error] = @object.errors.full_messages.join ', '
      redirect_back
    end

  end

  def show
    @object = UserDefinedObject.find params[:id]
    @title = @object.name
    respond_to do |format|
      format.js do
        render json: @object
      end
      format.html
    end
end

  def update
    @object = UserDefinedObject.find params[:id]

    #figures out which parameter(s) have changed and sets that parameters value, and assigns its specific save success message
    params[:user_defined_object].each do |k, v|
      @object.send("#{k}=", v)
    end

    @object.save ? flash[:success] = "Success!" : flash[:error] = @object.errors.full_messages.join(', ')
    #@UserDefinedObject.save ? flash[:success] = messages.join(',') : flash[:error] = @UserDefinedObject.errors.full_messages.join(', ')
    redirect_back fallback_location: root_path
  end

  def destroy
    UserDefinedObject.find(params[:id]).destroy
    flash[:success] = "Deleted UserDefinedObject"
    redirect_back
  end

  private

  def user_defined_object_params
    params.require(:user_defined_object).permit(:name, :object)
  end

end
