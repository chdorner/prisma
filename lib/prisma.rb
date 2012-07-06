require 'rails/all'
require 'redis-namespace'

require 'prisma/group'
require 'prisma/railtie'
require 'prisma/filter'

# Used for configuration, typically in a Rails initializer.
module Prisma
  mattr_reader :groups
  # @!visibility private
  @@groups = {}

  # @!visibility public
  # Set your own +Redis+ instance, it will be wrapped into a +Redis::Namespace+ object with the configured namespace.
  # Useful for when Redis is not available on the standard IP and port.
  # Allows:
  # - hostname:port
  # - hostname:port:db
  # - redis://hostname:port/db
  # - +Redis+ instance
  mattr_accessor :redis
  # @!visibility private
  @@redis = ::Redis.new

  # @!visibility public
  # String for redis namespace, defaults to +prisma+
  mattr_accessor :redis_namespace
  # @!visibility private
  @@redis_namespace = 'prisma' 

  # @!visibility public
  # Duration in seconds for expiring redis keys (easy to use with Rails duration helpers +1.day+)
  mattr_accessor :redis_expiration_duration

  # Configure prisma. Example usage:
  #     Prisma.setup do |config|
  #       config.group :active_api_clients { |controller| controller.current_client.id }
  #       config.redis = Redis.new(:db => 1)
  #       config.redis_namespace = 'stats'
  #       config.redis_expiration_duration = 2.days
  #     end
  def self.setup
    yield self
    store_configuration
  end

  # Configures a group. The instance of the current {http://api.rubyonrails.org/classes/ActionController/Base.html ActionController} is being passed as an argument into the block.
  # As an example, tracking daily active users could be as simple as:
  #     Prisma.setup do |config|
  #       config.group :logged_in { |controller| controller.current_user.id }
  #     end
  #
  # @param [Symbol/String] name for identifying the group, it is used as part of the redis key.
  # @param [String] description for describing the gorup, it is used in the admin interface.
  # @param [Block] block returning a String (or a meaningful +.to_s output+) which is used for identifying a counter inside a group, Prisma doesn't count a request if block returns +nil+ or +false+
  def self.group(name, description=nil, &block)
    @@groups[name] = Group.new(:name => name, :description => description, :block => block)
  end

  # Returns a default or configured +Redis+ instance wrapped in a +Redis::Namespace+
  # @return [Redis::Namespace]
  def self.redis
    @@namespaced_redis ||= lambda do
      case @@redis
      when String
        if @@redis =~ /redis\:\/\//
          redis = Redis.connect(:url => @@redis, :thread_safe => true)
        else
          host, port, db = @@redis.split(':')
          redis = Redis.new(:host => host, :port => port, :thread_safe => true, :db => db)
        end
        Redis::Namespace.new(redis_namespace, :redis => redis)
      else
        Redis::Namespace.new(redis_namespace, :redis => @@redis)
      end
    end.call
  end

  # @!visibility private
  # Returns redis key for a group name and optional date
  # @param [Symbol/String] group_name for which group the redis key is for
  # @param [Date] date for which date the redis key is for, if not given it uses today's date
  # @return [String] the redis key
  def self.redis_key(group_name, date=nil)
    date = Time.now.utc.to_date unless date
    "#{group_name}:#{date.strftime('%Y:%m:%d')}"
  end

  # @!visibility private
  # Returns duration of from beginning of day to now + given or configured duration
  # @param [Numeric] duration in seconds (defaults to configured +redis_expiration_duration+)
  # @return [Numeric] duration
  def self.redis_expire(duration=nil)
    duration = redis_expiration_duration unless duration
    (Time.now.utc.beginning_of_day + duration).to_i - Time.now.utc.to_i
  end

  # @!visibility private
  # Stores the configured groups inside of redis
  def self.store_configuration
    redis.del 'configuration'
    groups.values.each do |group|
      redis.hset 'configuration', group.name, group.description
    end
  end
end

