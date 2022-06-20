module KitsHelper
  
  include SessionsHelper
  
  def getUserIdFromTree(tree)
    raise
    user_id = -1
    if LDCI::CONFIG[:switch]
    else
      @mongo ||= Mongoldc::Connection.new
      journal = @mongo.ensure_journals.find_one( :_id => tree )
      if journal && journal['journal']
        user_index = journal['journal'][-1][0] == 'mongo' ? 2 : 1
        user_id = journal['journal'][-1][user_index]
      end
    end
    user_id
  end
  
  def getUserFromTree(tree)
    raise
    userString = String.new
    if LDCI::CONFIG[:switch]
    else
      @mongo ||= Mongoldc::Connection.new
      journal = @mongo.ensure_journals.find_one( :_id => tree )
      if journal && journal['journal']
        user_index = journal['journal'][-1][0] == 'mongo' ? 2 : 1
        if User.exists?(journal['journal'][-1][user_index])
          userString = "Last updated by: #{User.find(journal['journal'][-1][user_index]).name}"
        else
          userString = "Last updated by: deleted user with id: #{journal['journal'][-1][user_index]}"
        end
      else
        userString = "Tree exists, but journal does not"
      end
    end
    userString
  end
  
end
