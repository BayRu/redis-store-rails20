# Redis Store for Rails 2 apps

### Usage
Flagrantly stolen from Pedro Belo

Add to your Gemfile:

    gem "redis-store-rails20"

Require the gem:
    require 'redis-store-rails20'

Then configure Rails:

    config.cache_store = :redis_store_rails20

By default it will attempt to connect to Redis running at localhost. To change:

  config.action_controller.session = {
    :cache => MANUALLY_INITIALIZE_REDIS_STORE_RAILS20, #if you want a single connection and don't trust my connection caching
    :uri => URI_OF_REDIS,
    :host => hostname_running_redis,
    :port => port_redis_is_on
  }

  note that host and port override uri, but why would you specify both?
