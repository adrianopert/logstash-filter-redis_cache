# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This example filter will replace the contents of the default 
# message field with whatever you specify in the configuration.
#
# It is only intended to be used as an example.
class LogStash::Filters::Redis_Cache < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #   example {
  #     message => "My message..."
  #   }
  # }
  #
  config_name "redis_cache"
  
  # Name is used for logging in case there are multiple instances.
  # TODO: delete
  config :name, :validate => :string, :default => 'default',
    :deprecated => true

  # The hostname(s) of your Redis server(s). Ports may be specified on any
  # hostname, which will override the global port config.
  #
  # For example:
  # [source,ruby]
  #     "127.0.0.1"
  config :host, :validate => :string, :default => "127.0.0.1"

  # The default port to connect on. Can be overridden on any hostname.
  config :port, :validate => :number, :default => 6379

  # The Redis database number. Defaults to 1 to differenciate from redis plugin which writes to "0 database" by default.
  config :db, :validate => :number, :default => 1

  # Redis initial connection timeout in seconds.
  config :timeout, :validate => :number, :default => 5

  # Password to authenticate with.  There is no authentication by default.
  config :password, :validate => :password

  # The name of an existing field in event that will match the Redis key.
  config :key, :validate => :string, :required => true

  # List of fields to copy from the Redis cache
  config :fields, :validate => :array, :required => true

  # Interval for reconnecting to failed Redis connections
  config :reconnect_interval, :validate => :number, :default => 1


  public
  def register
    # Add instance variables 
		require "redis"
		@redis = nil
  end # def register

  public
  def filter(event)
    return unless filter?(event)

		key = event[@key]
    begin
      @redis ||= connect
      payload = @redis.get(key) || "" # null string if nil value is returned

    rescue => e
      @logger.warn("Failed to get cached fields from Redis", :event => event,
                   :identity => identity, :exception => e,
                   :backtrace => e.backtrace)
      sleep @reconnect_interval
      @redis = nil
      retry
    end

    begin
      # Get only the keys listed in @fields (first order keys). Prepare the event with some filters to assure the existence of the required fields.	
			if payload != ""
				LogStash::Json.load( payload ).each { |k, v|  event[k] = v if @fields.include?(k) }
			end

    rescue LogStash::Json::ParserError, ArgumentError
      puts "FAILUREDECODING"
      @logger.error("Failed to converting JSON cached fields.",
                    :event => event.inspect)
      return
    end

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter

  private
  def connect
    params = {
      :host => @host,
      :port => @port,
      :timeout => @timeout,
      :db => @db
    }
    @logger.debug(params)

    if @password
      params[:password] = @password.value
    end

    Redis.new(params)
  end # def connect

  # A string used to identify a Redis instance in log messages
  def identity
    @name || "redis://#{@password}@#{@current_host}:#{@current_port}/#{@db} #{@data_type}:#{@key}"
  end

end # class LogStash::Filters::Example
