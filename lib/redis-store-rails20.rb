require "active_support"
require 'redis'
require 'cgi/session'

class CGI::Session::RedisStoreRails20 

  class Error < StandardError; end
  def logger
    @logger||=Logger.new(STDERR)
  end
  def check_id(_id)
    return true if _id=~/^[0-9a-zA-Z]+$/
    return false
  end
  def initialize(session,opts)
    unless check_id(session.session_id)
      raise ArgumentError, "session_id '%s' is invalid" % session.session_id 
    end
    @store = opts['cache'] || opts[:cache]
     
    places_to_look = %w(address uri) 
    address = places_to_look.map{|e|opts[e]}.compact.first|| "redis://localhost:6379"
    @session_data = {}
    @session_key = "session:#{session.session_id}"
    

    uri = URI.parse(address)
    password = uri.password || uri.user
    h = uri.host || opts[:'host'] || opts[:'hostname'] || opts['host'] || opts['hostname'] || 'localhost'
    p = (uri.port || opts[:port] || opts['port'] || 6379).to_i
    @options  = { :host => h, :port => p }
    @options.merge!(:password => password) if password

    handle_errors do
      store # attempt to connect to Redis on boot
    end
  end
  def data
    @session_data
  end
  def restore 
    options = {}
    handle_errors(options) do
      k = store.get(@session_key)
      @session_data = Marshal.load(k) if k and k.is_a?(String)
      @session_data ||={}
    end
    @session_data
  end

  def write
    options = {}
    handle_errors({ :default_value => false }.merge(options)) do
      response = if ttl = options[:expires_in]
        store.setex(@session_key, ttl, Marshal.dump(@session_data))
      else
        store.set(@session_key,Marshal.dump(@session_data))
      end
      response == "OK"
    end
  end

  def delete
    options = {}
    handle_errors({ :default_value => false }.merge(options)) do
      response = store.del(@session_key)
      response >= 0
    end
    @session_data={}
  end
  def close
    self.write
  end


  protected
  class HashHash < Hash
    def hashhash(h)
      if h.is_a?(Hash)
        h.to_a.sort_by{|e|e.first.inspect}.inspect
      else
        h
      end
    end
    def set x,y
      super(hashhash(x),y)
    end 

    def get x
      super(hashhash(x))
    end 
    def []= x,y
      super(hashhash(x),y)
    end 

    def [] x
      super(hashhash(x))
    end 
  end 
  def self.connection_cache
    (@@connection_cache||=HashHash.new)
  end
  def store
    @store ||=begin
      self.class.connection_cache[@options]||= Redis.new(@options)
    end
  end

  class RedisTimeoutError < Exception; end

  def handle_errors(options = {})
    Timeout.timeout(0.2, RedisTimeoutError) do
      return yield
    end
  rescue Redis::BaseConnectionError, RedisTimeoutError => e
    logger.error("RedisStoreRails2 error (#{e.class.name}): #{e.message}")
    raise RedisStoreRails2::Error.new(e.to_s) if options[:raise_errors]
    options[:default_value]
  end
end
