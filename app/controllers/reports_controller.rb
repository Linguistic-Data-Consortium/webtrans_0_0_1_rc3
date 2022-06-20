class ReportsController < ApplicationController

  # include ReportsHelper

  before_action :authenticate
  before_action :check_user

  def show
    i = params[:id].to_i
    @i = i
    report = "Report#{i}".constantize.new(params: params)
    respond_to do |format|
      format.html
      format.json do
        render json: report.run
      end
      format.tsv do
        report.run
        send_data report.to_tsv, :filename => report.filename, :type => 'text/tab-separated-values'
      end
    end
  end

  private

  def check_user
    # redirect_to root_path unless current_user.name == 'ccieri' or admin?
  end

end

class Report1 < Report
  attr_accessor :filename, :table
  def initialize(params)
    @task = Task.find_by_name 'glg'
    @done_kits = ''
    @listitem = 'AudioListItem'
    @order = ''
    @nodes = %w[ Audio ChosenLanguage CorrectLanguage Choices Confidence ]
    @fields = [
      [ "Kit ID", :kit_id ],
      [ "IID", :iid ],
      [ "Time", :ctime ],
      [ "User ID", :user_id ],
      [ "Location", :ulocation ],
      [ "Data Set ID", :data_set_id ],
      [ "Task ID", :task_id ],
      [ "Audio", :n0 ],
      [ "ChosenLanguage", :n1 ],
      [ "CorrectLanguage", :n2 ],
      [ "Choices", :n3 ],
      [ "Confidence", :n4 ],
      [ "Country Code", :country_code ],
      [ "City", :city ]
    ]
  end
  
  def select_fields
    @game_variant = @task.game_variant
    data_set_id = @game_variant.meta['data_set'] || 'n/a'
    "      kits.id kit_id,
      p.iid iid,
      n1.created_at ctime,
      kits.user_id user_id,
      'unk' ulocation,
      '#{data_set_id}' data_set_id,
      kits.task_id task_id,
      v0.docid n0,
      v1.value n1,
      v2.value n2,
      v3.value n3,
      v4.value n4,
      kv1.value country_code,
      kv2.value city"
  end

  def query_string(h)
    query_string2 h
  end
  
  def query
    query_string query_hash
  end
  def query_hash
    {}
  end
end

class Report2 < Report

  attr_accessor :filename, :table

  def initialize(params)
    @task = Task.find 48
    @done_kits = "kits.state = 'done' and"
    @listitem = 'SegmentListItem'
    @order = 'order by kit_uid, n0b'
    @nodes = [ 'Segment', 'Transcription' ]
    @fields = [
      [ "Kit UID", :kit_uid, 'kits.uid' ],
      [ "Audio", :n0, 'v0.docid' ],
      [ "Beg", :n0b, 'v0.begr' ],
      [ "End", :n0e, 'v0.endr' ],
      [ "Transcript", :n1, 'v1.value' ]
    ]
  end
  
  def query
    query_string query_hash
  end

  def query_hash
    {}
  end

end

class Report3 < Report

  attr_accessor :filename, :table

  def initialize(params:)
    @task = Task.find params[:task_id]
    @done_kits = "kits.state = 'done' and"
    @listitem = 'SegmentListItem'
    @order = 'order by kit_uid, n0b'
    @nodes = [ 'Segment', 'Transcription' ]
    @fields = [
      [ "Kit UID", :kit_uid, 'kits.uid' ],
      [ "IID", :iid, 'p.iid' ],
      [ "Time", :ctime, 'n1.created_at' ],
      [ "User ID", :user_id, 'kits.user_id' ],
      [ "Data Set ID", :data_set_id, 'tasks.data_set_id' ],
      [ "Task ID", :task_id, 'kits.task_id' ],
      [ "Audio", :n0, 'v0.docid' ],
      [ "Beg", :n0b, 'v0.begr' ],
      [ "End", :n0e, 'v0.endr' ],
      [ "Transcript", :n1, 'v1.value' ],
      [ "Country Code", :country_code, 'kv1.value' ],
      [ "City", :city, 'kv2.value' ]
    ]
  end
  
  def query_string(h)
    query_string2 h
  end

  def query
    query_string query_hash
  end

  def query_hash
    {}
  end

end

module LDC
  module Reports

  end
end
