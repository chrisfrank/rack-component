require_relative 'component/component_cache'
require_relative 'component/refinements'

module Rack
  # Subclass Rack::Component to compose declarative, component-based responses
  # to HTTP requests
  class Component
    VERSION = '0.3.0'.freeze

    # Initialize a new component with the given args and render it.
    #
    # @example Render a HelloWorld component
    #   class HelloWorld < Rack::Component
    #     def initialize(name)
    #       @name = name
    #     end
    #
    #     def render
    #       "<h1>Hello #{@name}</h1>"
    #     end
    #   end
    #
    #   MyComponent.call(world: 'Earth') #=> '<h1>Hello Earth</h1>'
    # @return [String, Object] the output of instance#render
    def self.call(*args, &block)
      new(*args).render(&block)
    end

    # Override either #render or #exposures to make your component do work.
    # By default, the behavior of #render depends on whether you call the
    # component with a block or not: it either returns #exposures or yields to
    # the block with #exposures as arguments.
    #
    # @return [String, Object] usually a string, but really whatever
    def render
      block_given? ? yield(exposures) : exposures
    end

    # Override #exposures to keep the default yield-or-return behavior
    # of #render, but change what gets yielded or returned
    def exposures
      self
    end

    # Rack::Component::Memoized is just like Component, only it
    # caches its rendered output in memory and only rerenders
    # when called with new arguments.
    class Memoized < self
      CACHE_SIZE = 100 # limit to 100 keys by default to prevent leaking RAM

      # Access or instantiate a class-level cache
      # @return [Rack::Component::ComponentCache] a threadsafe in-memory cache
      def self.cache
        @cache ||= ComponentCache.new(const_get(:CACHE_SIZE))
      end

      # @example render a Memoized Component
      #   class Expensive < Rack::Component::Memoized
      #     def initialize(id)
      #       @id = id
      #     end
      #
      #     def work
      #       sleep 5
      #       "#{@id}"
      #     end
      #
      #     def render
      #       %(<h1>#{work}</h1>)
      #     end
      #   end
      #
      #   # first call takes five seconds
      #   Expensive.call(id: 1) #=> <h1>1</h1>
      #   # subsequent calls with identical args are instant
      #   Expensive.call(id: 1) #=> <h1>1</h1>, instantly!
      #
      #   # subsequent calls with _different_ args take five seconds
      #   Expensive.call(id: 2) #=> <h1>2</h1>
      #
      # @return [String, Object] the cached (or computed) output of render
      def self.call(*args, &block)
        memoized(*args) { super }
      end

      # Check the class-level cache, set it to &miss if nil.
      # @return [Object] the output of &miss.call
      def self.memoized(*args, &miss)
        cache.fetch(key(*args), &miss)
      end

      # @return [Integer] a cache key for this component
      def self.key(*args)
        args.hash
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
