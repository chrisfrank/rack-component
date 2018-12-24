require_relative 'component/version'
require_relative 'component/component_cache'

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
        ObjectSpace.each_object(singleton_class) do |descendant|
          descendant.send(:cache).flush
        end
      end

      def warm(*keys)
        ObjectSpace.each_object(singleton_class) do |descendant|
          keys.map { |key| descendant.call(key) }
        end
      end

      private

      def cache
        @cache ||= ComponentCache.new(const_get(:CACHE_SIZE))
      end

      def render(&block)
        define_method :call, &block
      end
    end

    attr_reader :env
    def initialize(env = {})
      @env = env
    end

    def call(*)
      block_given? ? yield(self) : self
    end
  end
end
