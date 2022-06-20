#
# => Redis DB 7 will be used for tracking of user activity
#
redis_host=ENV['REDIS_HOST'] || 'redis'
$active_users = Redis.new(host: redis_host, port: 6379, db: 7)
