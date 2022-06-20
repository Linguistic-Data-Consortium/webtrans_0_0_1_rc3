class PagesController < ApplicationController

  before_action :authenticate, :only => [
    :compatibility,
    :documentation
  ]
  # before_filter :admin, :only => :admin

  def home
    @mode = $ua['mode']
    case @mode
    when 'single', 'collection'
      if Server.count == 0
        Server.create(name: '')
      end
    end
    # sqlite2postgres
    if signed_in?
      case Server.first.name
      when 'glg'
        redirect_to '/ntl'
      else
        redirect_to user_path(@current_user)
      end
    elsif Server.count == 0
      @server = Server.new
      @init = true
    else
      case @mode
      when 'glg'
        redirect_to '/ntl'
      when 'webtrans'
        redirect_to '/webtrans'
      else
        @server = Server.new
        @failed = true # prevents repeated checking of the db in views
        @title = "Home"
        @user = User.new
      end
    end
  end

  def compatibility
  end

  def contact
    @title = "Contact"
  end

  def about
    @title = "About"
  end

  def consent
    @title = "Consent Form"
  end

  def help
    @title = "Help"
  end
  
  def waveform_help_screen
    render layout: false, content_type: 'text/html'
  end

  def service_help_screen
    render layout: false, content_type: 'text/html'
  end

  def level_testing_page
    render layout: false, content_type: 'text/html'
  end

  def admin
    @title = "Admin"
  end

  def documentation
    @title = "Documentation"
  end

  def versions
    @git = `git log | head -3`.chomp.split("\n")
    @tag = `git describe`
    @gems = `cat Gemfile.lock`
  end

  def echo
    respond_to do |format|
      format.json do
        render json: { time: Time.now.to_s }
      end
      format.html do
        render text: Time.now.to_s
      end
    end
  end

  def sqlite2postgres
    dba = Sequel.connect database: File.absolute_path("db/development.sqlite3"), adapter: 'sqlite'
    dbb = Sequel.connect ActiveRecord::Base.connection_config
    tables = dba.fetch("SELECT name FROM sqlite_master WHERE type='table';").to_a.map do |row|
      name = row[:name]
      name unless name.in? %w[ sqlite_sequence schema_migrations ar_internal_metadata ]
    end.compact
    tables.delete 'games'
    tables.unshift 'games'
    tables.map do |x|
      dba.fetch("select * from #{x} order by id").to_a.map do |y|
        y.delete :id
        y.delete :meta if x.in? %[ kits task_users ]
        y.delete :game_variant_id if x == 'kits'
        y.delete :data_set_id if x == 'tasks'
        y.delete :type if x == 'workflows'
        dbb[x.to_sym].insert y
      end
    end
    NodeValue.where(id:0).first_or_create
  end

  def check_your_email
  end

end
