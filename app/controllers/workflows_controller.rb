class WorkflowsController < ApplicationController

  before_action :authenticate

  def index
    respond_to do |format|
      format.json do
        render json: (
          if admin?
            a = Workflow.sorted.all
            b = [
              Workflow.find_by_name('OnTheFly'),
              Workflow.find_by_name('Orderly')
            ]
            a -= b
            (b + a).map(&:attributes)
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
          if portal_manager?
            h = Workflow.find(params[:id]).attributes
            h[:types] = [ nil ] + Workflow.subclasses.map(&:to_s)
            h
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
          if not portal_manager?
            { error: "Only a portal manager can create a workflow." }
          else
            workflow = Workflow.new workflow_params
            if workflow.save
              workflow.attributes
            else
              { error: workflow.errors.full_messages }
            end
          end
        )
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        render json: (
          if not portal_manager?
            { error: "Only a portal manager can edit the workflow." }
          else
            workflow = Workflow.find(params[:id])
            if workflow.update workflow_params
              workflow.attributes
            else
              { error: workflow.errors.full_messages }
            end
          end
        )
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        render json: (
          if not portal_manager?
            { error: "Only a portal manager can delete the workflow." }
          else
            workflow = Workflow.find(params[:id])
            workflow.destroy
            { deleted: "workflow: #{workflow.name} has been deleted." }
          end
        )
      end
    end
  end

  private

  def workflow_params
    params.require(:workflow).permit(:name, :user_states, :description, :type)
  end

end
