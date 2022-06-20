module AwsHelper
  def s3
    @s3 ||= client
  end
  
  def client
    # key, secret, region = ENV['BUCKET_CREDS'].split ','
    region = 'us-east-1'
    Aws::S3::Client.new region: region
  end

  def list_objects(bucket:)
    a = []
    list = true
    if bucket =~ /(.+)\/(.+)/
      params = { bucket: $1, prefix: $2 }
    else
      params = { bucket: bucket }
    end
    while list
      h = s3.list_objects_v2(params).to_h
      a += h[:contents]
      list = h[:is_truncated]
      params[:continuation_token] = h[:next_continuation_token] if list
    end
    if bucket == 'speechbiomarkers'
      a.select { |x| x[:key].length == 24 }
    else
      a
    end
  end

  def remaining_objects(excluding:, bucket:)
    list_objects(bucket: bucket).select { |x| not x[:key].in?(excluding) }
  end

  def bucket_size(bucket)
    list_objects(bucket: bucket).count
  end
  
  # get keys from bucket, excluding some and limiting total
  # keys sorted by modification time
  # allows the bucket/subbucket notation, but only one level deep
  def keys_from_bucket(excluding:, bucket:, limit:)
    objects = remaining_objects excluding: excluding, bucket: bucket
    objects = objects.sort_by { |x| x[:last_modified] }
    bucket = $1 if bucket =~ /(.+)\/(.+)/
    keys = []
    objects.each do |x|
      y = s3.head_object({bucket: bucket, key: x[:key]})
      # speechbiomarkers has extraneous objects
      if bucket == 'speechbiomarkers'
        if y[:metadata] and y[:metadata]['uid'] and y[:metadata]['uid'] =~ /^\d{10}-\d{8}T\d{6}Z-/
          keys << [ x[:key], y[:metadata]['uid'] ]
        end
      else
        keys << [ x[:key], x[:key] ]
      end
      break if keys.size == limit
    end
    keys
  end

end
