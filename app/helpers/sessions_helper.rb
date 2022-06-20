module SessionsHelper

  def authenticate
    if signed_in?
      confirm
    else
      deny_access
    end
  end

  def authenticate_or_die
    if signed_in?
      confirm
    else
      render nothing: true, status: :unauthorized
    end
  end
  def confirm
    store_location
    redirect_to '/confirmation' if request.format.html? and @current_user.confirmation_expired?
  end

  def deny_access
    store_location
    redirect_to root_path, :flash => {:error => 'Please sign in to access this page.'}
  end

  def log_in(user)
    session[:user_id] = user.id
  end

  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  def create_anonymously
    user = User.make_anon
    user.save!
    user.activate
    user
  end

  def login_anonymously
    user = create_anonymously
    log_in user
    remember user
    user
  end

  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  def current_user?(user)
    user == current_user
  end

  def logged_in?
    !current_user.nil?
  end

  def signed_in?
    !current_user.nil?
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def log_out
    forget current_user
    session.delete(:user_id)
    @current_user = nil
  end

  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get? and request.format.html?
  end

  def admin?
    signed_in? ? current_user.admin? : false
  end

  def admin_user
    unless admin?
      flash[:error] = "You must be a sysadmin to access this page."
      redirect_to(root_path)
    end
  end

  def portal_manager?
    signed_in? ? current_user.portal_manager? || current_user.admin? : false
  end

  def portal_manager_user
    unless portal_manager?
      flash[:error] = "You must be a Portal Manager to access this page."
      redirect_to(root_path)
    end
  end

  def project_manager?
    signed_in? ? current_user.project_manager? || portal_manager? : false
  end

  def project_manager_user
    unless project_manager?
      flash[:error] = "You must be a Project Manager to access this page."
      redirect_to(root_path)
    end
  end

  def lead_annotator?
    project_manager?
  end

  def lead_annotator_user
    project_manager_user
  end

  def project_designer_user
    if params['project_id']
      @project = Project.find(params['project_id'])
    elsif params[:id]
      @project = Project.find(params[:id])
    end
    project_admin?
  end

  def fill_in_project
    @project ||= Project.find(params[:id])
    @project ||= Project.find(params['project_id'])
    unless @project
      flash[:error] = "Project not found."
      redirect_to root_path
    end
  end

  def project_owner?
    fill_in_project
    signed_in? ? @project.owner?(current_user) || portal_manager? : false
  end

  def project_owner_user
    unless project_owner?
      flash[:error] = "You must be a Project Owner."
      redirect_to root_path
    end
  end

  def project_admin?
    fill_in_project
    signed_in? ? (@project.admin?(current_user) || project_owner?) : false
  end

  def project_admin_user
    unless project_admin?
      flash[:error] = "You must be a Project Admin."
      redirect_to root_path
    end
  end

  def fill_in_task
    @task ||= Task.find(params[:id])
    @task ||= Task.find(params['task_id'])
    unless @task
      flash[:error] = "Task not found."
      redirect_to root_path
    end
    @project = @task.project
    unless @project
      flash[:error] = "Project not found."
      redirect_to root_path
    end
  end

  def task_admin?
    fill_in_task
    signed_in? ? (@task.admin?(current_user) || project_admin?) : false
  end

  def pii_manager?
    false
  end

  def lead_annotator_user_kit_user
    if params[:kit_uid]
      kit = Kit.find_by_uid(params[:kit_uid])
      user_id = kit.user_id
      current_tasks = current_user.task_users.pluck(:task_id)
      return if kit.task_id.in?([435,436]) and 445.in? current_tasks #current_user.task_users.pluck(:task_id)
      return if kit.task_id.in? current_tasks #current_user.task_users.pluck(:task_id)
    end
    if user_id != current_user.id
      redirect_to(root_path) unless lead_annotator?
    end
  end

  def get_toolspp(path)
    h = JSON.parse(lui_http('webann.ldc.upenn.edu').get(path).body)
    get_toolsppp h, get_map2(h)
  end

  def toolspcd(x, map2)
    v = x['class_def']
    map2[v['id']] = ClassDef.where(name: v['name']).first_or_create
    map2[v['id']].update(css: v['css'])
  end

  # add/update one tool
  def get_toolspppp(h)
    # puts h['class_defs'].to_s
    map2 = get_map2(h)
    get_toolsppp h, map2
    map2.values.first.id
  end

  def get_map2(h)
    map2 = {}
    h['class_defs'].each do |x|
      toolspcd x, map2
    end
    map2
  end

  # for adding/updating lots of tools at once
  def get_toolsppp(h, map2)
    map = {}
    cbg = nil
    cb = nil
    leaf = NodeClass.where(name: 'Leaf').first_or_create
    leaf_id = leaf.id
    h['parents'].each do |x|
      v = x['node_class']
      if v['name'] == 'Leaf'
        map[v['id']] = leaf
      elsif v['name'].in? %w[ Checkbox Menu Entry Radio Textarea Ref Set ]
        map[v['id']] = v['name']
      elsif v['name'] == 'CheckboxGroup'
        map[v['id']] = 'Checkbox'
      else
        # cb = v['id'] if v['name'] == 'Checkbox'
        map[v['id']] = NodeClass.where(name: v['name']).first_or_create
      end
    end
    # map[cbg] = map[cb] if cbg and cb
    puts h
    h['node_classes'].each do |x|
      v = x['node_class']
      next if v['class_def_id'] > 9000
      puts v
      puts v['class_def_id']
      puts v['class_def_id'].class
      puts map2[v['class_def_id']]
      mapp = map[v['parent_id']]
      pid = if mapp.class == String
        pid = leaf_id
        v['constraints'] ||= {}
        if v['constraints']['classes'].nil?
          v['constraints']['classes'] = mapp
        else
          v['constraints']['classes'] << " #{mapp}"
        end
      else
        mapp.id
      end
      nc = case v['name']
      when 'GLG:ChosenLanguage'
        name_change_helper 'GLG:Lang', v['name']
      when 'GLG:CorrectLanguage'
        name_change_helper 'GLG:Correct', v['name']
      else
        NodeClass.where(name: v['name']).first_or_create
      end
      nc.update(
        parent_id: pid,
        children: v['children'],
        class_def_id: map2[v['class_def_id']].id,
        value: v['value'],
        constraints: v['constraints']
        )
    end
  end

  def name_change_helper(n, name)
    ncc = NodeClass.where(name: n).first
    if ncc
      ncc.update(name: name)
      ncc
    else
      NodeClass.where(name: name).first_or_create
    end
  end

  def lui_http(server)
    if server == 'localhost'
      http = Net::HTTP.new(server, 3000)
    else
      http = Net::HTTP.new(server, 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    http
  end
  def lui_http2(path)
    server = 'webann.ldc.upenn.edu'
    http = Net::HTTP.new(server, 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    r = Net::HTTP::Get.new path
    r.add_field('Origin:', 'http://example.org')
    JSON.parse(http.request(r).body)
  end
  def pii?
    false
  end

end
