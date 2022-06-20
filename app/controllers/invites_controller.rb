class InvitesController < ApplicationController
    before_action :authenticate,   except: [ :edit, :update ]
    before_action :get_user,       only:   [ :edit, :update ]
    before_action :valid_user,     only:   [ :edit, :update ]
  
    def index
      if lead_annotator?
        @title = "All Projects"
        @users = User.where(invite_sent_by: current_user.id)
        j = {}
        j[:users] = @users.map do |user|
          h = {
            id: user.id,
            email: user.email,
            sent: user.invite_sent_at,
            activated: user.activated
          }
          h
        end
        j[:tasks_index] = {}
        # ProjectUser.where(user_id: current_user.id, admin: true).each do |p|
        j[:projects] = Project.all.map do |p|
          j[:tasks_index][p.id] = p.tasks.map do |t| 
            {
              id: t.id,
              name: t.name
            }
          end
          {
            id: p.id,
            name: p.name
          }
        end
      else
        j = { error: 'not allowed' }
      end
      respond_to do |format|
        format.html
        format.json { render json: j }
      end
    end
  
    def edit
      if @user && !@user.activated? && @user.authenticated?(:invite, params[:id])
        respond_to do |format|
          format.html { render :edit, status: :ok }
        end
      else
        flash[:danger] = "Invalid invitation link"
        redirect_to root_url
      end
    end
  
    def update
      if @user && !@user.activated? && @user.authenticated?(:invite, params[:id])
        @user.update(user_params)
        pus = ProjectUser.where(user_id: @user.id)
        pus.each do |x|
          x.status = 'active'
          x.save
        end
        @user.activate
        log_in @user
        flash[:success] = "Account activated!"
        redirect_to root_url
      else
        flash[:danger] = "Invalid link"
        redirect_to root_url
      end
    end

    def create
      email_regex = /\A[\w+\-.#]+@[a-z\d\-.]+\.[a-z]+\z/i
      found = []
      if params[:email]
        good_invites = params[:email].split.map(&:chomp).select {|invite| invite.match(email_regex)}
        good_invites.each do |invite|
          new_user = User.find_by_email(invite)
          found << (if !new_user
            new_user = User.create(email: invite)
            # create gets rolled back
            new_user.create_invite_digest current_user.id
            # but then create_invite_digest saves the model, skipping validations
            new_user.send_invitation_email
            "sending to #{invite}"
          else
            if new_user.activated?
              "#{invite} has already been activated"
            elsif new_user.invite_sent_by == nil
              "#{invite} was created already"
            elsif new_user.invite_sent_by == current_user.id
              new_user.send_invitation_email
              "#{invite} exists, resending invitation"
            else
              "#{invite} was invited by someone else"
            end
          end)
          if params[:role] == "Project Manager" && portal_manager?
            g = Group.find_by_name 'Project Managers'
            g.users << new_user
            found << "#{invite} was added as Project Manager"
          end
          if params[:role] == "Portal Manager" && admin?
            g = Group.find_by_name 'Portal Managers'
            g.users << new_user
            found << "#{invite} was added as Portal Manager"
          end
          if params[:project_id]
            if ProjectUser.where(project_id: params[:project_id], user_id: current_user.id, admin: true).length == 1 or
               ProjectUser.where(project_id: params[:project_id], user_id: current_user.id, owner: true).length == 1 or
               project_manager?
              p = Project.find params[:project_id]
              p.users << new_user
              found << "#{invite} was added to project"
              if params[:task_id]
                t = Task.find params[:task_id]
                t.users << new_user
                found << "#{invite} was added to task"
              end
            else
              found << "you're not an admin for the project"
            end
          end
        end
      else
        found << "no emails given"
      end
      if found.length == 0
        found << "no valid emails found"
      end
      j = { errors: [ found ] }
      respond_to do |format|
        format.json { render json: j }
      end
    end

    private
  
    def get_user
      @user = params[:email] ? User.find_by(email: params[:email]) : User.find_by(email: params[:user][:email])
    end
  
    # Confirms a valid user.
    def valid_user
      unless (@user && 
              @user.authenticated?(:invite, params[:id]))
        redirect_to root_url
      end
    end

    def user_params
      if params.dig(:user,:profile_attributes,:gender_radio)
        gender = params[:user][:profile_attributes][:gender_radio]
        if params[:user][:profile_attributes][:gender_other]
          gender = params[:user][:profile_attributes][:gender_other]
        end
        params[:user][:profile_attributes][:gender] = gender
        params[:user][:profile_attributes].delete(:gender_radio)
        params[:user][:profile_attributes].delete(:gender_other)
      end
      params.require(:user).permit(:name, :ack_name, :email, :password, :password_confirmation, :terms_agreed, profile_attributes: [:year_of_birth, :gender, :cities, :languages_known])
    end
  end
