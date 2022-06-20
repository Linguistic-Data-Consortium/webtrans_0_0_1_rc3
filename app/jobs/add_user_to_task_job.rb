class AddUserToTaskJob < ApplicationJob

  queue_as :default

  def perform(task, user)
    case task.id
    when 999999
      list.each do |uid|
        create_kit task, user, uid
      end
    end
  end

  def create_kit(task, user, uid)
    kt = task.kit_type
    @kit = Kit.new
    @kit.task_id = task.id
    @kit.user_id = user.id
    @kit.kit_type_id = kt.id
    @kit.state = 'unassigned'
    @kit.source = { uid: uid, id: uid, type: 'document' }
    @kit.save!
  end


  def list
    %w[
      FTD001_MG-20190717_182114-picnic_scene
      FTD001_MG-20190717_182531-pool_color_v1
      FTD001_MG-20190717_182848-cookie_theft
      FTD001_MG-20190717_182940-fluency
      FTD001_MG-20190717_183159-market_color_v2
      FTD002_NP-20190717_194741-pool_color_v1
      FTD002_NP-20190717_195050-cookie_theft
      FTD002_NP-20190717_195424-market_color_v2
      FTD002_NP-20190717_195506-fluency
      FTD002_NP-20190717_195619-picnic_scene
      FTD003_NN-20190717_203301-market_color_v2
      FTD003_NN-20190717_203630-picnic_scene
      FTD003_NN-20190717_204017-cookie_theft
      FTD003_NN-20190717_204100-fluency
      FTD003_NN-20190717_204237-pool_color_v1
      FTD004_NI-20190717_200326-pool_color_v1
      FTD004_NI-20190717_200733-market_color_v2
      FTD004_NI-20190717_201250-picnic_scene
      FTD004_NI-20190717_201338-fluency
      FTD004_NI-20190717_201507-cookie_theft
      FTD005_SB-20190717_202000-cookie_theft
      FTD005_SB-20190717_202338-picnic_scene
      FTD005_SB-20190717_202711-market_color_v2
      FTD005_SB-20190717_202758-fluency
      FTD005_SB-20190717_202907-pool_color_v1
      FTD006_FN-20190722_205849-picnic_scene
      FTD006_FN-20190722_210320-market_color_v2
      FTD006_FN-20190722_210651-cookie_theft
      FTD006_FN-20190722_210739-fluency
      FTD006_FN-20190722_210910-pool_color_v1
    ]
  end

end
