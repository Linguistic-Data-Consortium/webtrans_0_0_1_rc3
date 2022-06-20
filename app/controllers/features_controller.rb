class FeaturesController < ApplicationController

  before_action :authenticate

  def index
    respond_to do |format|
      format.json do
        render json: (
          if admin?
            Feature.sorted.all.map(&:attributes)
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: (
          if admin?
            Feature.find(params[:id]).attributes
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        render json: (
          if not admin?
            { error: "Only an admin can create a feature." }
          else
            feature = Feature.new feature_params
            if feature.save
              feature.attributes
            else
              { error: feature.errors.full_messages }
            end
          end
        )
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        render json: (
          if not admin?
            { error: "Only an admin can edit the feature." }
          else
            feature = Feature.find(params[:id])
            if feature.update feature_params
              feature.attributes
            else
              { error: feature.errors.full_messages }
            end
          end
        )
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        render json: (
          if not admin?
            { error: "Only an admin can delete the feature." }
          else
            feature = Feature.find(params[:id])
            feature.destroy
            { deleted: "feature: #{feature.name} has been deleted." }
          end
        )
      end
    end
  end

  private

  def feature_params
    params.require(:feature).permit(:category, :name, :value, :label, :description)
  end

end
