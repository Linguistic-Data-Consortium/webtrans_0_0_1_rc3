class PreAnnJob < ApplicationJob
  queue_as :default

  def perform(kit, text)
    @text = text
    # KitValue.where(kit_id: kit.id, key: 'pre_ann', value: "first").first_or_create
    return if kit.sum == 1.0
    kit.sum = 1.0
    kit.save
    # return unless KitValue.where(kit_id: kit.id, key: 'pre_ann', value: "first").update_all(value: 'locked') == 1
    # return if AnnotationJournal.where(kit_id: kit.id).count > 0
    c = AnnotationJournal.last.id
    if c < 10000
      @list_id = 37
      @grammar ||= AnnotationJournal.last.grammar
    else
      @list_id = 36
      @grammar ||= AnnotationJournal.find(1354821).grammar
    end
    name = kit.source_uid.split('/').last
    key = "results/transcripts/segmented/#{name}.json"
    o = JSON.parse client.get_object( bucket: 'promise-uploads', key: key).body.read
    iid = 4
    t = 0
    o.each do |line|
      if line[2] == 'speech'
        create_line(kit: kit, iid: iid.to_s, b: line[0], e: line[1], transcript: line[3])
        t += 1
        iid += 4
      end
    end
    KitValue.where(kit_id: kit.id, key: 'pre_ann', value: "locked").update_all(value: "#{t},#{iid}")
    # KitValue.where(kit_id: kit.id, key: 'pre_ann', svalue: "#{t},#{iid}").first_or_create
  end

  def create_line(kit:, iid:, b:, e:, transcript:)
    AnnotationJournal.create(
      json: messages(kit, iid, b, e, transcript),
      grammar: @grammar,
      user_id: 1,
      task_id: kit.task_id,
      kit_id: kit.id,
      tree_id: kit.tree_id
    )
  end

  def messages(kit,start,b,e,t)
    iid1 = (start.to_i+1).to_s
    iid2 = (start.to_i+2).to_s
    a = [
      {
        "node" => "1",
        "message" => "add",
        "value" => @list_id
      },
      {
        "node" => iid1,
        "message" => "change",
        "value" => {
          "docid" => kit.source_uid,
          "beg" => b,
          "end" => e,
          "play_head" => b,
          "node" => iid1,
          "level" => 1
        }
      }
    ]
    if t and @text
      a.push({
        "node" => iid2,
        "message" => "change",
        "value" => { "value" => t }
      })
    end
    h = {
      "messages" => a,
    #  "client_time" => 1626703199168,                                                                                  
      "kit_uid" => kit.uid
    }
    h.to_json
  end

  def client
    Aws::S3::Client.new region: 'us-east-1'
  end

end
