require "active_support"
require "active_support/cache"

class RedisStoreRails2 < ActiveSupport::Cache::Store

  class Error < StandardError; end

  def initialize(address=nil)
    address ||= "redis://localhost:6379"

    uri = URI.parse(address)
    options  = { :host => uri.host, :port => uri.port }
    password = uri.password || uri.user
    options.merge!(:password => password) if password
    @store = Redis.new(options)
  end

  def read(key, options = nil)
    super
    handle_errors(options) do
      @store.get(key)
    end
  end

  def write(key, value, options={})
    super
    handle_errors({ :default_value => false }.merge(options)) do
      response = @store.set(key, value)
      @store.expire(key, options[:expires_in]) if options[:expires_in]
      response == "OK"
    end
  end

  def delete(key, options={})
    super
    handle_errors({ :default_value => false }.merge(options)) do
      response = @store.del(key)
      response >= 0
    end
  end

  def increment(key, amount = 1)
    handle_errors(options) do
      return nil unless @store.exists(key)
      @store.incrby key, amount
    end
  end

  def decrement(key, amount = 1)
    handle_errors(options) do
      return nil unless @store.exists(key)
      @data.decrby key, amount
    end
  end

  def clear
    handle_errors(options) do
      @store.flushdb
    end
  end

  protected

  def handle_errors(options)
    return yield
  rescue Errno::ECONNREFUSED => e
    logger.error("RedisStoreRails2 error (#{e}): #{e.message}")
    raise ::Error if options[:raise_errors]
    options[:default_value]
  end
end
