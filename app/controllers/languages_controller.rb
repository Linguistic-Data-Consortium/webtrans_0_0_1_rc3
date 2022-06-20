class LanguagesController < ApplicationController

  before_action :admin_user, :except => [:index, :autocomplete]
  before_action :lead_annotator_user
  before_action :authenticate

  def autocomplete
    @languages = Language.all.order(:ref_name).where("ref_name LIKE ?", "%#{params[:term]}%").map(&:ref_name).to_json
    respond_to do |format|
      format.json { render json: @languages }
    end
  end

  def new
    redirect_to languages_path
  end

  def index
    @title = "All Languages"
    @langs = Language.all
    @lang = Language.new
    respond_to do |format|
      format.html
      format.json {
        if params[:json_format] == 'datatable'
          render json: {"aaData" => data(@langs)}
        else
          render json: @langs
        end
      }
    end
  end

  def edit
    @lang = Language.find(params[:id])
    redirect_to @lang
  end

  def show
    @lang = Language.find(params[:id])
    @title = @lang.ref_name
  end

  def create
    @lang = Language.new(language_params)
    if @lang.save
      flash[:success] = "New language: #{@lang.ref_name} created"
      redirect_to @lang
    else
      flash[:error] = @lang.errors.full_messages.join(", ")
      redirect_back(fallback_location: root_path)
    end
  end

  def update
    @lang = Language.find(params[:id])
    if @lang.update(language_params)
      flash[:success] = "Language #{@lang.ref_name} updated"
    else
      flash[:error] = @lang.errors.full_messages.join(", ")
    end
      redirect_back(fallback_location: root_path)
  end

  def destroy
    lang = Language.find(params[:id])
    lname = lang.ref_name
    lang.destroy
    flash[:success] = "Language #{lname} has been deleted."
    redirect_back(fallback_location: root_path)
  end

  private

  def language_params
    params.require(:language).permit(:language_id, :iso_id, :lang_scope, :lang_type, :ref_name, :comment, :custom, :id, :ldc_code, :description)
  end

  def data(languages)
    languages.map do |language|
      [
        language.iso_id,
        language.ldc_code,
        view_context.link_to(language.ref_name, language),
        language.description,
        language.comment,
        language.custom,
      ]
    end
  end
end
