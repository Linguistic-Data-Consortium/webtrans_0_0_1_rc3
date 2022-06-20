class FileSetsController < ApplicationController

  before_action :authenticate

  def create
    source = FileSet.create!(file_set_params)
    # source.update(uid: source&.file&.blob.key) if source.uid.nil?
    # TreesJob.perform_later source
    respond_to do |format|
      format.html do
        redirect_to root_path
      end
      format.json do
        render json: { id: source.id, uid: source.uid, type: 'file_set' }
      end
    end
  end

  def get_uploads
    @file_set = FileSet.new
    respond_to do |format|
      format.html do
        render partial: 'uploads'
      end
    end
  end

  # def show
  #   file_set = FileSet.find params[:id]
  #   o = file_set.files.map do |file|
  #     file.blob.download.chomp.split("\n").map do |line|
  #       a, b, c = line.split
  #       [ a.to_f, b.to_f, c ]
  #     end
  #   end
  #   respond_to do |format|
  #     format.json do
  #       render json: o
  #     end
  #   end
  # end


  private
  
  def file_set_params
    params.require(:file_set).permit(:uid, files: [])
  end

end
