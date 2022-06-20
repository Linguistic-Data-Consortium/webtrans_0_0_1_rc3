module CollectionsHelper

  def generic_helper1(name)
    store_location
    @project = Project.where(name: name).first_or_create
    @project.save if @project.id.nil?
    @collection = Collection.where(name: name, project_id: @project.id, collection_type_id: 1).first_or_create
    @user ||= User.new
    gid = Group.where(name: name).first_or_create.id
    @group = GroupUser.where(group_id: gid).pluck(:user_id)
    @mimic = params[:mimic]
  end

  def edu_degree_options
    [["None", "none"], ["High School Diploma or equivalent", "hsorged"], ["Some college, no degree", "somecol"], # ["Postsecondary nondegree award", "postnon"],
     ["Associates Degree", "associate"], ["Bachelors Degree", "bachelor"], ["Masters Degree", "master"], ["Doctorate or professional degree", "phd"]]
  end

  def year_options
    (1910..Time.current.year).to_a
  end

  def generate_pin
    used_pins = Enrollment.where(collection_id: @enrollment.collection_id).pluck(:pin)
    pin = nil
    loop do
      pin = 4.times.map{ rand(0..9) }.join
      break if !used_pins.include?(pin)
    end
    @enrollment.pin = pin
  end

end
