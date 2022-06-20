class RecordersController < ApplicationController

  before_action :authenticate

  def show
    @source = Source.new
    @sr = params[:sr]
    respond_to do |format|
      format.html
      format.json do
        if params[:blobs]
          render json: ActiveStorage::Blob.all
        elsif params[:source_uid]
          @source = Source.where(uid: params[:source_uid]).first
          render json: { @source.uid => url_for(@source.file) }
        elsif params[:blob_id]
          @source = Source.find ActiveStorage::Attachment.where(blob_id: params[:blob_id], record_type: 'Source').first.record_id
          render json: { @source.uid => url_for(@source.file) }
        else
          render json: {}
        end
      end
    end
  end

end
