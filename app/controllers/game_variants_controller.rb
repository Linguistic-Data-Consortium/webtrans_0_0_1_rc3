class GameVariantsController < ApplicationController
  before_action :authenticate
  before_action :admin_user

  def autocomplete
    @game_variants = GameVariant.order(:name).where("name LIKE ?", "%#{params[:term]}%").map(&:name).to_json
    respond_to do |format|
      format.json { render json: @game_variants }
    end
  end

  def index
    @title = "All game variants"
    @game_variants = GameVariant.all
    @game_variant = GameVariant.new
    @games = Game.all
  end

  def create
    @game_variant= GameVariant.new game_variant_params
    if @game_variant.save
      flash[:success] = "New game: #{@game_variant.name} created"
      redirect_to @game_variant
    else
      flash[:error] = @game_variant.errors.full_messages.join(", ")
      redirect_back(fallback_location: root_path)
    end
  end

  def edit
    @game_variant= GameVariant.find(params[:id])
    redirect_to @game_variant
  end

  def update
    @game_variant = GameVariant.find(params[:id])
    if @game_variant.update(game_variant_params)
      flash[:success] = "Game Variant updated"
    else
      flash[:error] = @game_variant.errors.full_messages.join(", ")
    end
    redirect_back(fallback_location: root_path)
  end

  def show
    @game_variant= GameVariant.find(params[:id])
    @title = @game_variant.name
    @games = Game.all
  end

  def destroy
    game_variant_name = GameVariant.find(params[:id]).name
    GameVariant.find(params[:id]).destroy
    flash[:success] = "GameVariant: #{game_variant_name} has been deleted."
    redirect_back(fallback_location: root_path)
  end

  private

  def game_variant_params
    if params[:game_variant].has_key?(:meta)
      jsonified = JSON.parse(params[:game_variant][:meta])
      @game_variant_params ||= params.require(:game_variant).permit(:name, :game_id, meta: jsonified.keys)
      @game_variant_params[:meta] = jsonified
    else
      @game_variant_params ||= params.require(:game_variant).permit(:name, :game_id)
    end
    @game_variant_params
  end
end
