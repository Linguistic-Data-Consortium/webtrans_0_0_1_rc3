class ConstantsController < ApplicationController
  before_action :authenticate

  # require 'ldc/constants'
  #include LDC::Constants::Bolt

  # get a json object with all of these in javascript with var x; $.get("/constants", function(obj){ x = obj;}, 'json');
  # x.constantname gets you the constant you desire
  def index
    constants_hash = {}
    LDC::Constants::Deft.constants.each { |x| constants_hash.store(x, LDC::Constants::Deft.const_get(x)) }
    respond_to do |format|
      format.json { render json: constants_hash  }
    end
  end

end
module LDC
  module Constants
  end
end
module LDC::Constants::Deft

  INFERENCE_CLASS_DEF_ID = 385
  INFERENCE_KIT_TYPE_ID = 195
  INFERENCE_TASK_ID = 196

  dn = File.join __dir__, 'deft'
  Dir["#{dn}/*.yaml"].each do |fn|
    n = File.basename(fn, '.yaml').upcase
    eval "#{n} = YAML.load_file fn"
  end
 
end
