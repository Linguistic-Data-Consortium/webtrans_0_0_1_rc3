fn = Rails.root.join('ua.config')
$ua = {}
$ua = YAML.load File.read fn if File.exists? fn
puts $ua.to_yaml

if File.exists? "tmp/init_db_for_#{ENV['POSTGRES_DB']}"

  if $ua['class_defs']
    $ua['class_defs'].each do |x|
      class_def_name = x['name']
      cd = ClassDef.where(name: class_def_name).first_or_create
      cd.update(css: x['css'])
      x['node_classes'].each do |x|
        nc = NodeClass.where(name: x['name']).first_or_create
        children = x['children']
        children = children.split.map { |x| "#{x}.#{class_def_name}:#{x}" }.join ',' if children and children !~ /\./
        nc.update(
          class_def_id: cd.id,
          parent_id: NodeClass.find_by_name(x['parent']).id,
          value: x['value'],
          children: children,
          constraints: x['constraints']
        )
      end
    end
  end

  if $ua['projects']
    $ua['projects'].each do |x|
      name = x['name']
      if name
        p = Project.where(name: name).first_or_create
        tasks = x['tasks']
        if tasks
          puts "found #{tasks.count} tasks"
          tasks.each do |x|
            name = x['name']
            w = Workflow.where(name: x['workflow']['name'], type: x['workflow']['type']).first_or_create
            kt = KitType.where(name: x['kit_type']['name']).first_or_create
            kt.update(
              javascript: 'empty',
              node_class_id: NodeClass.where(name: x['kit_type']['node_class']).pluck(:id).first,
              constraints: x['kit_type']['constraints']
            )
            if name
              t = Task.where(
                project_id: p.id,
                name: name,
                workflow_id: w.id,
                kit_type_id: kt.id
              ).first_or_create
            end
          end
        else
          puts 'no tasks'
        end
      end
    end
  end
  
  if $ua['sources']
    $ua['sources'].each do |x|
      Source.where(uid: x).first_or_create
    end
  end

end
