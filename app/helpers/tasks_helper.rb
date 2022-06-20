module TasksHelper
  
  #function that returns the save success message for a given field/value pair
  def save_messages(field, value)
    if field == 'help'
      "#{start_message[field]}"
    elsif field == 'kit_type_id'
      "#{start_message[field]} #{@task.kit_type_composite_name}"
    else
      "#{start_message[field]} #{value}" 
    end
  end
  
  private
  
  #hash that contains a map between field names and success message beginning
  def start_message
    {
      'name' => "Name updated to ",
      'workflow_id' => "Workflow updated to  ",
      'kit_type_id' => "Kit Type updated to ",
      'help' => 'Help description updated'
    }
  end
end
