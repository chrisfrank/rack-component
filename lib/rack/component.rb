require_relative 'component/component_cache'

module Rack
  # Subclass Rack::Component to compose declarative, component-based responses
  # to HTTP requests
  class Component
    VERSION = '0.1.0'.freeze

    EMPTY = ''.freeze # components render an empty body by default
    attr_reader :props

    # Initialize a new component with the given props and #call() it.
    #
    # @example render a HelloWorld component
    #   class HelloWorld < Rack::Component
    #     def world
    #       props[:world]
    #     end
    #
    #     def call
    #       %(<h1>Hello #{world}</h1>)
    #     end
    #   end
    #
    #   MyComponent.call(world: 'Earth') #=> '<h1>Hello Earth</h1>'
    # @return [String, Object] the output of instance#call
    def self.call(*props, &block)
      new(*props).render(&block)
    end

    def initialize(props = {})
      @props = props
    end

    # Override call to make your component do work.
    # @return [String, Object] usually a string, but really whatever
    def render
      block_given? ? yield(self) : EMPTY
    end

    # Rack::Component::Memoized is just like Component, only it
    # caches its rendered output in memory and only rerenders
    # when called with new props.
    class Memoized < self
      CACHE_SIZE = 100 # limit cache to 100 keys by default so we don't leak RAM

      # instantiate a class-level cache if necessary
      # @return [Rack::Component::ComponentCache] a threadsafe in-memory cache
      def self.cache
        @cache ||= ComponentCache.new(const_get(:CACHE_SIZE))
      end

      # @example render a Memoized Component
      #   class Expensive < Rack::Component::Memoized
      #     def work
      #       sleep 5
      #       "#{props[:id]} was expensive"
      #     end
      #
      #     def call
      #       %(<h1>#{work}</h1>)
      #     end
      #   end
      #
      #   # first call takes five seconds
      #   Expensive.call(id: 1) #=> <h1>1 was expensive</h1>
      #   # subsequent calls with identical props are instant
      #
      #   # subsequent calls with _different_ props take five seconds
      #   Expensive.call(id: 2) #=> <h1>2 was expensive</h1>
      #
      # @return [String, Object] the cached (or computed) output of render
      def self.call(*props, &block)
        memoized(*props) { super }
      end

      # Check the class-level cache, set it to &miss if nil.
      # @return [Object] the output of &miss.call
      def self.memoized(*props, &miss)
        cache.fetch(key(*props), &miss)
      end

      # @return [Integer] a cache key for this component
      def self.key(*props)
        props.hash
      end

      # Clear the cache of each descendant class.
      # Generally you'll call this on Rack::Component::Memoized directly.
      # @example Clear all caches:
      #   Rack::Component::Memoized.clear_caches
      def self.clear_caches
        ObjectSpace.each_object(singleton_class) do |descendant|
          descendant.cache.flush
        end
      end
    end
  end
end
