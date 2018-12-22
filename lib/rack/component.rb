require_relative 'component/component_cache'

module Rack
  # Subclass Rack::Component to compose declarative, component-based responses
  # to HTTP requests
  class Component
    VERSION = '0.3.0'.freeze
    CACHE_SIZE = 100 # limit cache to 100 keys by default to prevent leaking RAM
    class << self
      def call(env = {}, &children)
        new(env).call env, &children
      end

      def cached(env = {}, &children)
        cache.fetch(env.hash) { call(env, &children) }
      end

      def flush
        ObjectSpace.each_object(singleton_class) do |descendant|
          descendant.send(:cache).flush
        end
      end

      def warm(*keys)
        ObjectSpace.each_object(singleton_class) do |descendant|
          Array(keys).map { |key| descendant.call(key) }
        end
      end

      private

      def cache
        @cache ||= ComponentCache.new(const_get(:CACHE_SIZE))
      end

      def render(&block)
        define_method :render, &block

        define_method :call do |props, &children|
          render(props, &children)
        end
      end
    end

    attr_reader :env
    def initialize(env = {})
      @env = env
    end

    def call(env)
      block_given? ? yield(self) : self
    end
  end
end
