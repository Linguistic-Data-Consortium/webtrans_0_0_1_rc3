class GlgController < ApplicationController

  def index
    # get_toolspp '/class_defs/487.json' unless ClassDef.where(name: 'GLG').count == 1
    # get_toolsppp YAML.load(File.read('lib/nieuw.yaml'))
    # h = JSON.parse(lui_http('webann.ldc.upenn.edu').get('/nieuw').body)
    # @hh = {}
    # @hh['class_defs'] = h['class_defs'].select { |x| x['class_def']['id'] == 487 }
    # @hh['node_classes'] = h['node_classes'].select { |x| x['node_class']['class_def_id'] == 487 }
    # @hh['parents'] = h['parents']
    # render plain: @hh.to_yaml
    # get_toolsppp @hh
  end

  def windex
  end

  def consent
  end

  def play
    @project = Project.where(name: 'glg').first_or_create
    @kit_type = KitType.where(name: 'glg', node_class_id: NodeClass.find_by_name('GLG:Root').id).first_or_create
    @kit_type.constraints['web_audio'] = 'web_audio'
    @kit_type.constraints['manifest'] = 'manifest'
    @kit_type.save!
    @game = Game.where(name: 'glg').first_or_create
    @gv = GameVariant.where(name: 'glg', game_id: @game.id).first_or_create
    @task = Task.where(name: 'glg').first
    @task ||= Task.where(name: 'glg', project_id: @project.id, kit_type_id: @kit_type.id, workflow_id: Workflow.find_by_name('OnTheFly').id, game_variant_id: @gv.id).first_or_create
    login_anonymously if current_user.nil?
    @tu = TaskUser.where(task_id: @task.id, user_id: current_user.id).first_or_create
    redirect_to "/workflows/#{@tu.id}/work/#{@task.workflow_id}"
  end
  def wplay
    @project = Project.where(name: 'webtrans').first_or_create
    @kit_type = KitType.where(name: 'webtrans', node_class_id: NodeClass.find_by_name('SimpleTranscription:Root').id, javascript: 'empty').first_or_create
    @kit_type.constraints['web_audio'] = 'web_audio'
    # @kit_type.constraints['manifest'] = 'manifest'
    @kit_type.save!
    @task = Task.where(name: 'webtrans', project_id: @project.id, kit_type_id: @kit_type.id, workflow_id: Workflow.find_by_name('OnTheFly').id).first_or_create
    @task.meta['docid'] = 'sw02001_A'
    @task.save!
    login_anonymously if current_user.nil?
    @tu = TaskUser.where(task_id: @task.id, user_id: current_user.id).first_or_create
    redirect_to "/workflows/#{@tu.id}/work/#{@task.workflow_id}"
  end

end
