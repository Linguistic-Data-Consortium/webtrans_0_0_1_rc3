class GamesController < ApplicationController

  before_action :admin_user

  def new
    redirect_to games_path
  end

  def index
    @title = "All games"
    @games = Game.all
    @game = Game.new
  end

  def edit
    @game = Game.find(params[:id])
    redirect_to @game
  end

  def show
    @game = Game.find(params[:id])
    @title = @game.name
  end

  def create
    @game = Game.new game_params
    if @game.save
      flash[:success] = "New game: #{@game.name} created"
      redirect_to @game
    else
      flash[:error] = @game.errors.full_messages.join(", ")
      redirect_back(fallback_location: root_path)
    end
  end

  def update
    @game = Game.find(params[:id])
    if @game.update(game_params)
      flash[:success] = "Game renamed to #{@game.name}"
    else
      flash[:error] = @game.errors.full_messages.join(", ")
    end
    redirect_back(fallback_location: root_path)
  end

  def destroy
    gname = Game.find(params[:id]).name
    Game.find(params[:id]).destroy
    flash[:success] = "Game: #{gname} has been deleted."
    redirect_back(fallback_location: root_path)
  end

  private

  def game_params
    params.require(:game).permit(:name)
  end

end
