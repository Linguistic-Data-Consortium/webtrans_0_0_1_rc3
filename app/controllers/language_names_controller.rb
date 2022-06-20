class LanguageNamesController < ApplicationController
  before_action :authenticate

  def autocomplete
    puts "\n\nlanguage_names_controller#autocomplete(#{params})\n"
    pat="%#{params[:term]}%"
    lang_names = LanguageName.joins(:language).where("lower(language_names.name) LIKE lower(?) or lower(languages.iso_id) LIKE lower(?)", pat, pat).order(:name)
    @names = lang_names.map do |lang_name|
      "#{lang_name.name} (#{lang_name.language.iso_id})"
    end
    respond_to do |format|
      format.json { render json: @names }
    end
  end
end
