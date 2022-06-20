class DemographicProfilesController < ApplicationController

  before_action :admin_user, :only => [:edit, :update, :destroy, :show, :index]
  before_action :authenticate

  def create
    @demographic_profile = DemographicProfile.new(demographic_profile_params)
    @demographic_profile.save ? flash[:success] = "Demographic information has been saved successfully." : flash[:error] = @demographic_profile.errors.full_messages.join(", ")
    redirect_back(fallback_location: root_path)
  end

  private

  def demographic_profile_params
    params.require(:demographic_profile).permit(:gender, :year_of_birth, :edu_years, :edu_degree, :edu_degree_year, :edu_contiguous, :ethnicity, :occupation, :height, :weight, :smoker, :user_id, :telco_subj_id, :gpe_where_born_id, :gpe_where_raised_id, :gpe_of_residence_id, :handedness, :edu_lang_primary_id, :edu_lang_secondary_id, :edu_lang_college_id, :edu_lang_graduate_id)
  end

end
