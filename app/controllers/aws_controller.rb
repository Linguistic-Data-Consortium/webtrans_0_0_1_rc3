class AwsController < ApplicationController
  
  def get
    respond_to do |format|
      format.json do
        render json: URI.parse(params[:url]).read
      end
    end
  end
  
end
