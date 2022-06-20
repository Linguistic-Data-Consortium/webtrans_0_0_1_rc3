class KitTypesController < ApplicationController
  include KitTypesHelper

  before_action :authenticate

  def autocomplete
    @kit_types = KitType.order(:name).where("name LIKE ?", "%#{params[:term]}%").map(&:name).to_json
    respond_to do |format|
      format.json { render json: @kit_types }
    end
  end

  def index
    respond_to do |format|
      format.json do
        render json: (
          if lead_annotator?
            KitType.sorted.all.map(&:attributes)
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: (
          if lead_annotator?
            kit_type = KitType.find(params[:id])
            if kit_type.meta['root'].nil?
              kit_type.meta['root'] = NodeClass.where(parent_id: NodeClass.find_by_name('Root')).last.name
              kit_type.save
            end
            if kit_type.meta['js'].nil?
              kit_type.meta['js'] = 'empty'
              kit_type.save
            end
            node_class = NodeClass.where(name: kit_type.meta['root']).first_or_create
            kit_type.update(node_class_id: node_class.id)
            {
              id: kit_type.id,
              name: kit_type.name,
              node_class_id: node_class.id,
              node_classes: NodeClass.sorted_root_nodes.map { |x| { id: x.id, name: x.name.split(':').first } },
              # feature_files: feature_files,
              # manifest: kit_type.constraints.has_key?('manifest')
              constraints: kit_type.constraints,
              features: Feature.where(category: 'kit_type').map(&:attributes)
            }
          else
            { error: 'Permission denied.' }
          end
        )
      end
    end
  end


  def create
    respond_to do |format|
      format.json do
        render json: (
          if not lead_annotator?
            { error: "Only a project manager can create a kit type." }
          else
            kit_type = KitType.new kit_type_params
            kit_type.meta = {}
            kit_type.node_class_id = NodeClass.where(parent_id: NodeClass.find_by_name('Root')).last.id
            kit_type.constraints = {}
            if kit_type.save
              kit_type.attributes
            else
              { error: kit_type.errors.full_messages }
            end
          end
        )
      end
    end
  end
    # params[:kit_type][:constraints].split(" ").each {|x| @kit_type.constraints.store(x, "")}

  def edit
    show_helper
    respond_to do |format|
      format.html do
        html = render_to_string partial: 'show'
        render json: { html: html }
      end
    end
  end

  def update
     respond_to do |format|
       format.json do
         kit_type = KitType.find params[:id]
         render json: (
           if not lead_annotator?
             { error: "Only a project manager can edit a kit type." }
           elsif params[:node_class_id]
             kit_type.node_class_id = params[:node_class_id].to_i
             if kit_type.save
               kit_type
             else
                { error: kit_type.errors.full_messages }
              end
           elsif params[:constraints]
             Feature.where(category: 'kit_type').uniq.each do |x|
               if params[:constraints].has_key? x.name
                 if x.name == x.value
                   if params[:constraints][x.name]
                     kit_type.constraints[x.name] = x.name
                   else
                     kit_type.constraints.delete x.name
                   end
                 else
                   if params[:constraints][x.name] and (params[:constraints][x.name].class != String or params[:constraints][x.name].length > 0)
                     kit_type.constraints[x.name] = params[:constraints][x.name]
                   else
                     kit_type.constraints.delete x.name
                   end
                 end
               end
             end
             if kit_type.save
               kit_type
             else
                { error: kit_type.errors.full_messages }
              end
           elsif kit_type.update kit_type_params
             kit_type
           else
             { error: kit_type.errors.full_messages }
           end
         )
       end
     end
   end

  def update_name
    @kit_type = KitType.find params[:id]
    @kit_type.name = params[:kit_type][:name]
    save_kit_type("Name updated to #{@kit_type.name}.")
    redirect_back(fallback_location: root_path)
  end

  # def update_type
  #   @kit_type = KitType.find params[:id]
  #   @kit_type.type = params[:kit_type][:type]
  #   save_kit_type("Type updated to #{@kit_type.type}.")
  #   redirect_back
  # end

  def update_constraints
    @kit_type = KitType.find params[:id]
    @kit_type.constraints = {}
    # params[:kit_type][:constraints].split(" ").each {|x| @kit_type.constraints.store(x, "")}
    if params[:constraints2]
      @kit_type.constraints = YAML.load params[:constraints2]
    else
      params.each do |k, v|
        next if k.in? %w[ utf8 _method authenticity_token commit controller action id ]
        @kit_type.constraints[k] = v
      end
    end
    save_kit_type("Features set: #{@kit_type.constraints.keys()}.")
    redirect_back(fallback_location: root_path)
  end

  # def update_meta
  #   @kit_type = KitType.find params[:id]
  #   @kit_type.meta['root'] = params[:kit_type][:root]
  #   @kit_type.meta['js'] = params[:kit_type][:js]
  #   @kit_type.meta['empty_list'] = params[:kit_type][:empty_list]
  #   @kit_type.meta['coref_groups'] = params[:kit_type][:coref_groups].split(',')
  #   @kit_type.meta['view'] = params[:kit_type][:view]
  #   @kit_type.meta['template'] = params[:kit_type][:template]
  #   @kit_type.meta['source'] = params[:kit_type][:source]
  #   save_kit_type("Meta updated to #{@kit_type.meta.to_s[0..100]}...")
  #   redirect_back
  # end

  def destroy
    respond_to do |format|
      format.json do
        render json: (
          if not lead_annotator?
            { error: "Only a project manager can delete a kit_type." }
          else
            kit_type = KitType.find(params[:id])
            kit_type.destroy
            { deleted: "kit_type: #{kit_type.name} has been deleted." }
          end
        )
      end
    end
  end

  private

  def kit_type_params
    params.require(:kit_type).permit(:name, :node_class_id, :source_id, :config_id, :meta, :annotation_set_id, :constraints)
  end

  def save_kit_type(success_str)
    @kit_type.save ? flash[:success] = success_str : flash[:error] = @kit_type.errors.full_messages.join(", ")
  end

end
