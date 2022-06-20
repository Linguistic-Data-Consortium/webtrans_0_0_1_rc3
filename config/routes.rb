Rails.application.routes.draw do

  resources :guidelines

  post '/aws', to: 'aws#get'

  get '/chat', to: 'chat#show'
  post '/current_user', to: 'chat#current'
  post '/chat', to: 'chat#create'
  post '/refresh_ttl', to: 'appearance#refresh'

  get '/bluejeans', to: 'collected_urls#new'
  resources :collected_urls
  get '/bluejeans/public_fields', to: 'collected_urls#get_public_fields'
  get '/collected_urls/public_fields', to: 'collected_urls#get_public_fields'
  get '/check_your_email', to: 'pages#check_your_email'
  resources :trees
  resources :file_sets
  resource :browser, only: :show
  get 'browser/transcription', to: 'browsers#transcription'
  get 'browser/index', to: 'browsers#index'
  get 'browser/tabs', to: 'browsers#tabs'
  resource :recorder, only: :show
  resources :transcripts
  

  get 'password_resets/new'

  get 'password_resets/edit'

  get :echo, to: 'pages#echo'
  root 'pages#home'
  get :help, :to => 'pages#help'
  get :about_study, to: 'pages#about'
  get :consent, to: 'pages#consent'
  get :waveform_help_screen, to: 'pages#waveform_help_screen'
  get :service_help_screen, to: 'pages#service_help_screen'
  get :level_testing_page, to: 'pages#level_testing_page'
  get :compatibility, to: 'pages#compatibility'
  get :documentation, to: 'pages#documentation'
  get '/signup', to: 'users#new'
  post '/signup', to: 'users#create'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  get '/confirmation', to: 'sessions#confirmation'
  post '/confirm', to: 'sessions#confirm'
  delete '/logout', to: 'sessions#destroy'
  get '/logout2', to: 'sessions#destroy2'
  get '/update_namespaces', to: 'servers#get_tools'
  get '/servers/ntl', to: 'servers#glg'
  get '/ntl', to: 'glg#index'
  post '/ntl/play', to: 'glg#play'
  get '/webtrans', to: 'glg#windex'
  post '/webtrans/play', to: 'glg#wplay'
  get '/ntl/consent', to: 'glg#consent'
  post '/users/single', to: 'users#single'
  resources :servers
  resources :users
  post "/users/create_enrollment", to: "users#create_enrollment"
  resources :sessions, only: [:create]
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]

  resources :kit_batches, only: [ :index, :show, :new, :create ]
  resources :user_defined_objects, as: :user_defined_objects

  resources :annotations
  get '/preann', to: 'annotations#preann'
  resources :reports

  resources :project_builder, only: [:new]
  get 'project_builder/project', :to => 'project_builder#project'
  get 'project_builder/choose_project', :to => 'project_builder#choose_project'
  get 'project_builder/task', :to => 'project_builder#task'
  get 'project_builder/choose_task', :to => 'project_builder#choose_task'
  get 'project_builder/dataset', :to => 'project_builder#dataset'
  get 'project_builder/choose_dataset', :to => 'project_builder#choose_dataset'
  get 'project_builder/tool', :to => 'project_builder#tool'
  get 'project_builder/template', :to => 'project_builder#template'
  patch 'project_builder/create_template', :to => 'project_builder#create_template'
  get 'project_builder/widget', :to => 'project_builder#widget'
  get 'project_builder/templateselection', :to => 'project_builder#templateselection'
  post 'project_builder/create_widget', :to => 'project_builder#create_widget'
  post 'projects/respond_with_project', :to => 'projects#respond_with_project'
  get 'projects/:id/research_team', :to => 'projects#research_team', :as => 'projects_research_team'
  get 'projects/:id/users_not_in_project', to: 'projects#users_not_in_project', :as => 'users_not_in_project'
  get 'groups/:id/users_not_in', to: 'groups#users_not_in', :as => 'users_not_in'
  get 'projects/:id/project_users', to: 'projects#project_users', :as => 'project_project_users'
  get 'tasks/:id/task_users', to: 'tasks#task_users', :as => 'task_task_users'
  post 'tasks/respond_with_task', :to => 'tasks#respond_with_task'
  get 'tasks/recreate', :to => 'tasks#recreate'
  post 'data_sets/respond_with_dataset', :to => 'data_sets#respond_with_dataset'

  post 'add_user_to_project_and_task/:project_id/:task_id', :to => 'projects#add_user_to_project_and_task', :as => 'add_user_to_project_and_task'


  get "/image_description", to: "image_description#index"

  get "/level_testing", to: "level_testing#index"



  get 'class_defs_index2', to: "class_defs#index2"
  post 'editclassdef', to: "class_defs#editclassdef"
  resources :node_classes
  resources :nodes
  resources :trees
  resources :node_values
  resources :nde_values
  resources :constants
  resources :kit_batches, only: [ :index, :show, :new, :create ]
  resources :tasks, :except => [:new, :create]#if the task already exists, we can infer the project, for new/create it must be specified
  resources :preference_types
  resources :preference_settings
  resources :projects, except: [ :new, :edit ] do
    resources :tasks, except: [ :new, :edit, :index ] do
      member do
        get :kit_creator
        post :file_upload
        post :kit_generation_preview
        post :generate_kits
        post :process_kits
        post :process_kits_preview
        get :reassign_kit
        get :kit_processor
        patch :reassign_many_kits
      end
    end
  end
  resources :task_users, :only => [ :show, :create, :update, :destroy ]
  resources :project_users
  post "/project_users/invite", to: "project_users#invite", as: "project_users_invite"
  post "/users/invite", to: "users#invite", as: "users_invite"
  # resources :kit_types
  # resources :class_defs
  # resources :node_values
  # resources :node_values
  # resources :node_values
  get "/kits/all", to: 'kits#all'
  get "/kits_new", to: 'kits#kits_new'
  post "/create_kits_from_kits_tab", to: 'kits#create_kits_from_kits_tab'
  resource :kits do
    member do
      get ':id/unlock_tree', action: :unlock_tree, as: :unlock_tree
      get :get
      patch :change_kit_state
      post :get_time_spent
      get :get_time_spent
      post :change_time_spent
      get :change_time_spent
      post :get_message_from_journal
      post :mongo_results
      get :mongo_query
      get ':id/show', :action => :show, :as => :show
      patch ':id/update', :action => :update, :as => :update
      get 'task/:id', :action => :task, :as => :task
      post :set_kits_done
      get 'fix_floating_kits/:task/:new_state', :action => :fix_floating_kits, :as => :fix_floating_kits
      get :management
      get :trouble
      get ':id/undo', action: :undo
    end
  end
  post '/duration', to: 'kits#duration'

  resources :workflows do
    member do
      get 'read_only/:kit_id', to: 'task_users#read_only'
      # get 'quality_control/:kit_id/:task_id', :action => 'quality_control'
      get 'work/:workflow_id', to: 'task_users#get'
      # get 'work/:task_user_id/:value', :action => 'work'
      get 'set/:task_user_id/:value', :action => 'set'
      # get 'set_lock/:state', :action => 'set_lock'
    end
  end
  resources(:class_defs) do
    resources :node_classes do
      member do
        post :add_child
      end
    end
    member do
      get :css
      get :edit_css
      post :update_css
      get :tree_viewer
      get :preview
      get :release
      post :clone
      post :update_bootstrap_mode
      post :increment_version
      get 'set_lock/:state', :action => :set_lock
      get :tables
      get :create_tables
    end
  end

  resources :kit_types do
    get 'autocomplete', :on => :collection
    member do
      patch :update_name
      patch :update_type
      patch :update_meta
      patch :update_constraints
    end
  end
  resources :styles do
    member do
      post 'style_manager/:cid', :action => :style_manager
      post 'add_style/:cid', :action => :add_style
      post :add_property
    end
  end

  resources :games
  resources :game_variants do
    get 'autocomplete', :on => :collection
  end

  resources :data_sets do
    member do
      get 'get_urls'
    end
  end

  resource :sources do
    member do
      get :text
      get :audio
      get :audio_full
      post :get_text
      post :get_ner
      post :uget
      get :ugett
      post :uget_public
      get :get_upload
      get :get_download
      get :new
    end
  end

  resource :file_set do
    member do
      get :get_uploads
    end
  end

  resources :languages do
    get 'autocomplete', :on => :collection
  end

  resources :demographic_profiles
  resources :groups, except: [ :new, :edit ]
  resources :group_users, :only => [:create, :destroy]

  resources :enrollments do
    member do
      get :withdrawn
      post :toggle_participant_active
      post :update_demographics
    end
  end

  resources :collections
  resources :invites
  resources :features, except: [ :new, :edit ]
  resources :scripts, except: [ :new, :edit ]

  get '/bucket', to: 'data_sets#bucket'
  post '/token', to: 'cognito_token#get_credentials'

end
