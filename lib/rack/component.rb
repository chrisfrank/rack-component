require_relative 'component/version'
require_relative 'component/memory_cache'

module Rack
  # Subclass Rack::Component to compose declarative, component-based responses
  # to HTTP requests
  class Component
    class << self
      def call(env = {}, &children)
        new(env).call env, &children
      end

      def cached(env = {}, &children)
        cache.fetch(env.hash) { call(env, &children) }
      end

      def flush
        cache.flush
      end

      def warm(*keys)
        keys.map { |key| cached(key) }
      end

      private

      def render(&block)
        define_method :call, &block
      end

      def cache
        @cache ||= (block_given? ? yield : MemoryCache.new(length: 100))
      end
    end

    def initialize(env = {})
      @env = env
    end

    def call(*)
      block_given? ? yield(env) : env
    end

    attr_reader :env
  end
end
