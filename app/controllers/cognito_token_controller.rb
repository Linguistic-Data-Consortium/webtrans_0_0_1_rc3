class CognitoTokenController < ApplicationController
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def initialize
    super
    @pool_id = Rails.application.config.cognito_identity_pool_id
    @provider_name = Rails.application.config.cognito_provider_name
  end
  # get a cognito token linked to the currently logged in user
  def get_credentials
    puts "\nnew token\n"
    params = {
      identity_pool_id: @pool_id,
      logins: { @provider_name => current_user.id.to_s },
      token_duration: 15 * 60 # 15 min validitiy; it's the default, but be explicit
    }
    cog = Aws::CognitoIdentity::Client.new
    tmp = cog.get_open_id_token_for_developer_identity(params).data.to_h
    tok = {
      identityId: tmp[:identity_id],
      logins: { 'cognito-identity.amazonaws.com': tmp[:token] }
    }
    respond_to do |format|
      format.json { render json: tok }
    end
  end
end
