class BrowsersController < ApplicationController

  before_action :authenticate

  def show
    @source = Source.new
    @file_set = FileSet.new
    @mode = params[:id] || 'none'
    @du = `du -hsx storage`
    respond_to do |format|
      format.html
      format.json do
        if params[:blobs]
          # render json: ActiveStorage::Blob.all
          # sources = Source.with_attached_file.all
          sources = if params[:task_id]
            Source.with_attached_file.includes(:user, :task).where(task_id: params[:task_id])
          else
            Source.with_attached_file.includes(:user, :task).where(user_id: current_user.id)
          end
          render json: sources.map { |x|
            next unless x.file.attached?
            next if params[:blobs] == 'audio' and (not x.file.blob.content_type.in? [ 'audio/wav', 'audio/x-wav' ])
            b = x.file.blob
            {
              source_id: x.id,
              filename: b.filename,
              key: b.key,
              user_id: x.user_id,
              task_id: x.task_id,
              user: x.user&.name,
              task: x.task&.name
            }
          }.compact
        else
          render json: {}
        end
      end
    end
  end
  
  def tabs
    @source = Source.new
    @file_set = FileSet.new
    @du = `du -hsx storage`
    render partial: 'tabs', layout: false, content_type: 'text/html'
  end

  def index
    render json: { this: 'that' }
  end

end
