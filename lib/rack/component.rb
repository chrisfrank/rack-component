require_relative 'component/component_cache'

module Rack
  # Subclass Rack::Component to compose declarative, component-driven
  # responses to HTTP requests
  class Component
    EMPTY = ''.freeze # components render an empty body by default
    attr_reader :props

    # Initialize a new component with the given props, and render it
    #
    # @example render a HelloWorld component
    #   class HelloWorld < Rack::Component
    #     def world
    #       props[:world]
    #     end
    #
    #     def render
    #       %(<h1>Hello #{world}</h1>)
    #     end
    #   end
    #
    #   MyComponent.call(world: 'Earth') #=> '<h1>Hello Earth</h1>'
    # @return [String, Object] the rendered component instance
    def self.call(props = {}, &block)
      new(props).call(&block)
    end

    def initialize(props = {})
      @props = props
    end

    # Render component
    # @return [Object] the result of self.render
    def call(&block)
      render(&block)
    end

    private

    # Override render to customize a component
    # @return [String, Object] usually a string, but really whatever
    def render
      block_given? ? yield(self) : EMPTY
    end

    # Rack::Component::Memoized is just like Component, only it
    # caches its rendered output in memory and only rerenders
    # when called with new props or a new block.
    class Memoized < self
      CACHE_SIZE = 100 # limit cache to 100 keys by default

      # instantiate a class-level cache if necessary
      # @return [Rack::Component::ComponentCache] a threadsafe in-memory cache
      def self.cache
        @cache ||= ComponentCache.new(const_get(:CACHE_SIZE))
      end

      # clear the cache of each descendant class
      # generally you'll want to call this on Rack::Component::Memoized directly
      # @example Rack::Component::Memoized.flush_caches
      def self.clear_caches
        ObjectSpace.each_object(singleton_class) do |descendant|
          descendant.cache.flush
        end
      end

      # @return[String] the rendered component instance from cache,
      # or by executing the erb template when not cached
      def call(&block)
        memoized { render(&block) }
      end

      # Check the class-level cache, set it to &miss if nil
      # @return [Object] the output of &miss.call
      def memoized(&miss)
        self.class.cache.fetch(key, &miss)
      end

      # a unique key for this component, based on a cryptographic signature
      # of the component props
      # @return [Integer]
      def key
        props.hash
      end
    end
  end
end
