class KitsDatatable
  
  include KitsHelper
  
  delegate :params, :link_to, :link_to, :user_path, :current_user, to: :@view

  def initialize(view, task, state, showDocId)
    @view = view
    @task = task
    @state = state
    @showDocId = showDocId
    @task_user = TaskUser.where( task_id: @task, user_id: current_user.id ).first
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Kit.where(:task_id => @task.id, :state => @state).count,
      iTotalDisplayRecords: kits.count,
      aaData: data
    }
  end

private

  def data
    #create the mappings of rows for the kits found
    annotations = {}
    Ann.where(kit_id: kits.map(&:id)).each do |ann|
      a = annotations[ann.kit_id]
      annotations[ann.kit_id] = ann if a.nil? or ann.id > a.id
    end
    kits.map do |kit|
      result = [
       kit.state,
        link_to(kit.uid, "/workflows/#{@task.workflow_id}/read_only/#{kit.uid}", :target => '_blank')
      ]
      # result.concat [link_to('quality control', "/workflows/#{@task.workflow_id}/quality_control/#{kit.uid}/#{@task.id}", :target => '_blank')] if @state == 'done'
      if @state == 'assigned'
        if @task_user
          result.concat [link_to('continue', "/workflows/#{@task.workflow_id}/work/#{@task_user.id}?kit_id=#{kit.id}", :target => '_blank')]
        else
          result.concat [link_to('not a member', "/projects/#{@task.project_id}/tasks/#{@task.id}")]
        end
      end
      result.concat [kit.respond_to?('docid') ? kit.docid : "none"] if @showDocId
      result.concat [
        kit.user ? kit.user_name : '',
        # link_to('reassign', '#', :kit_id => kit.uid, :class => 'reassign_kit', :data => {:toggle => 'modal', :target => "#reassign_kit_modal"})
        "<div class=\"reassign_kit modal-trigger\" kit_id=\"#{kit.uid}\">reassign</div>"
      ]
      result << kit.broken_comment if @state == 'broken'
      # result << kit.updated_at.getlocal
      ann = annotations[kit.id]
      result << (ann ? ann.updated_at.getlocal : 'none')
      result
    end
  end

  def kits
    @kits ||= fetch_kits
  end

  def fetch_kits
    kits = Kit.where(:task_id => @task.id, :state => @state).includes(:user).order("#{sort_column} #{sort_direction}")
    # kits = kits.page(page).per_page(per_page)
    if params[:sSearch].present?
      #joins makes any kits without user_id's disappear, so do two separate searches to catch the user id and then add the results together 
      searchResult1 = kits.where("uid like :search or broken_comment like :search", search: "%#{params[:sSearch]}%")
      searchResult2 = kits.joins(:user).where("users.name like :search", search: "%#{params[:sSearch]}%")
      kits = searchResult1 + searchResult2
    end
    kits
  end
  
  #start point for the current page array
  def start_point 
    (page-1)*per_page
  end
  
  #end point for the current page array
  def end_point
    start_point+per_page-1
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[state uid]
    columns << 'uid' if @state == 'assigned'
    columns << 'uid' if @showDocId
    columns.concat %w[user_id uid]
    columns << 'broken_comment' if @state == 'broken'
    columns << 'created_at'
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
