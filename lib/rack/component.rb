require_relative 'component/component_cache'

module Rack
  # Subclass Rack::Component to compose declarative, component-based responses
  # to HTTP requests
  class Component
    VERSION = '0.3.0'.freeze
    CACHE_SIZE = 100 # limit cache to 100 keys by default to prevent leaking RAM
    class << self
      attr_reader :_block

      def render(&block)
        @_block = block
      end

      def call(env = {}, &children)
        new(env, &children).instance_exec env, children, &_block
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

    end

    def initialize(env = {}, &children)
      @env = env
      @children = children
    end

    def children(args = self)
      @children ? @children.call(args) : self
    end

    attr_reader :env
  end
end
