module WorkflowsHelper

  def javascript_exists?(script)
    script_full = "#{Rails.root}/app/javascript/entrypoints/#{script}.js"
    File.exists? script_full
  end

  def stylesheet_exists?(script)
    script_full = "#{Rails.root}/app/assets/stylesheets/#{script}.css"
    File.exists?(script_full) || File.exists?("#{script_full}.coffee") 
  end

  #function that returns the save success message for a given field/value pair
  def save_messages(field, value)
    if field == 'description'
      "#{start_message[field]}"
    else
      "#{start_message[field]} #{value}"
    end
  end

  #hash that contains a map between field names and success message beginning
  def start_message
    {
      'name' => "Name successfully updated to ",
      'user_states' => "User states updated to ",
      'description' => "Description updated",
      'type' => 'Type updated to '
    }
  end

  def unprotect_annotations(x)
    return if Rails.env.development?
    unprotect_annotations2 x
  end

  def unprotect_annotations2(x)
    if x['children']
      if x['meta']['list']
        x['children'].each do |x|
          unprotect_annotations2 x
        end
      else
        x['children'].each do |k|
          unprotect_annotations2 x[k]
        end
      end
    else
      if x['value']
        if x['meta']['name'].in? %w[ CorefFinished ]
          return if x['value']['value'] == [ 'finished' ]
        end
        case x['value']['value']
        when String
          x['value']['value'] = unprotect(x['value']['value']).force_encoding('UTF-8') unless x['value']['value'] == ''
        when Array
          x['value']['value'].map! { |x| unprotect(x).force_encoding('UTF-8') }
        end
        case x['value']['text']
        when String
          x['value']['text'] = unprotect(x['value']['text']).force_encoding('UTF-8') unless x['value']['text'] == ''
        end
      end
    end
  end

  def unprotect(x)
    c = OpenSSL::Cipher::AES128.new(:CBC)
    c.decrypt
    ckey, civ = LDCI::CONFIG[:cipher]
    c.key = ckey
    c.iv = civ
    c.update(x) + c.final
  end

  def list_objects(existing:, bucket:)
    @s3 = Aws::S3::Client.new region: 'us-east-1'
    a = []
    list = true
    if bucket =~ /(.+)\/(.+)/
      params = { bucket: $1, prefix: $2 }
    else
      params = { bucket: bucket }
    end
    while list
      h = @s3.list_objects_v2(params).to_h
      a += h[:contents]
      list = h[:is_truncated]
      params[:continuation_token] = h[:next_continuation_token] if list
    end
    if bucket == 'speechbiomarkers'
      a.select { |x| x[:key].length == 24 and not x[:key].in?(existing) }
    else
      a.select { |x| not x[:key].in?(existing) }
    end
  end
  
  def bucket_size(bucket)
    list_objects(existing: [], bucket: bucket).count
  end

  def keys_from_bucket(existing:, bucket:)
    objects = list_objects existing: existing, bucket: bucket
    objects = objects.sort_by { |x| x[:last_modified] }
    keys = []
    objects.each do |x|
      y = @s3.head_object({bucket: bucket, key: x[:key]})
      if bucket == 'speechbiomarkers'
        if y[:metadata] and y[:metadata]['uid'] and y[:metadata]['uid'] =~ /^\d{10}-\d{8}T\d{6}Z-/
          keys << [ x[:key], y[:metadata]['uid'] ]
        end
      else
        keys << [ x[:key], x[:key] ]
      end
      break if keys.size == 10
    end
    keys
  end


end
