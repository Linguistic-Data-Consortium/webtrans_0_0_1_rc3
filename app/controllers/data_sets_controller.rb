class DataSetsController < ApplicationController

  before_action :authenticate

  def bucket
    s3 = Aws::S3::Client.new region: 'us-east-1'
    h = s3.list_buckets
    render json: {
      bucket: ENV['BUCKET_CREDS'],
      buckets: h.buckets.map { |x| { name: x.name } }
    }
  end
  
  def index
    index_all model: DataSet, only: :project_manager
  end

  def show
    respond_to do |format|
      format.json do
        render json: (
          if project_manager?
            data_set = DataSet.find(params[:id])
            if params[:file_id]
              { file: data_set.files.select { |x| x.id.to_s == params[:file_id] }.first.blob.download }
            elsif params[:file_name]
              { file: data_set.files.select { |x| x.blob.filename.to_s.include?(params[:file_name]) }.first.blob.download }
            else
              {
                id: data_set.id,
                name: data_set.name,
                description: data_set.description,
                manifest_url: (data_set.manifest.attached? ? url_for(data_set.manifest) : nil),
                files: data_set.files.map { |x|
                  {
                    id: x.id,
                    name: x.blob.filename,
                    type: x.blob.content_type
                  }
                }
              }
            end
          # the following allows transcripts to load, but it's too lax in general
          elsif params[:file_name]
            data_set = DataSet.find(params[:id])
            { file: data_set.files.select { |x| x.blob.filename.to_s.include?(params[:file_name]) }.first.blob.download }
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  def create
    createj model: DataSet, params: data_set_params, only: :project_manager
  end

  def createx
    randomize = params[:data_set][:randomize].to_s.downcase == "true"
    @data_set = DataSet.new data_set_params
    if DataSet.last
      dsid = (DataSet.last.id + 1).to_s
    else
      dsid = "1"
    end
    @data_set.name = @data_set.name + " " + dsid
    if @data_set.save
      flash[:success] = "New data set: #{@data_set.name} created"
      # data sets created by the project builder will execute this block
      if params[:data_set][:for_task]
        task = Task.find(params[:data_set][:for_task])
        # task.current_user = current_user
        helpers.prepare_for_project_builder(@data_set, task, randomize) 
        respond_to do |format|
          format.json { render json: { data_set: @data_set } }
          format.html { redirect_back(fallback_location: root_path) }
        end
      else
        redirect_to @data_set
      end
    else
      error = @data_set.errors.full_messages.join(", ")
      respond_to do |format|
        format.html { flash[:error] = error; redirect_back(fallback_location: root_path)}
        format.json { render json: { error: error } }
      end
    end
  end

  def update
    updatej model: DataSet, p: params, params: data_set_params, only: :project_manager
  end

  def destroy
    destroyj model: DataSet, params: params, only: :project_manager
  end

  def respond_with_dataset
    @data_set = DataSet.find(params[:data_set][:id])
    @task = Task.find(params[:task_id])
    # @task.current_user = current_user
    @task.data_set = @data_set
    @task.save
    respond_to do |format|
      format.json { render json: { data_set: @data_set } }
    end
  end

  def get_urls
    @data_set = DataSet.find(params[:id])
    render json: @data_set.files.map { |x| url_for x }
  end

  private

  def data_set_params
    params[:data_set].delete(:randomize)
    params.require(:data_set).permit(:name, :description, :spec, :manifest, :randomize, :files => [])
  end

end
