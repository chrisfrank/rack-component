require 'erb'
require 'rack/response'
require_relative 'component/component_cache'

module Rack
  # Subclass Rack::Component to compose declarative, component-driven
  # responses to HTTP requests
  class Component
    attr_reader :props, :block
    alias env props

    # Handle a Rack request
    # @param [Hash] env a rack ENV hash
    # @return [Array] a finished Rack::Response tuple
    def self.call(env)
      catch :halt do
        new(env).finish
      end
    end

    def initialize(props = {}, &block)
      @props = props
      @block = block
    end

    # Render component as a string
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
    #   MyComponent.new(world: 'Earth').to_s #=> '<h1>Hello Earth</h1>'
    #   "#{MyComponent.new(world: 'Earth')}" #=> '<h1>Hello Earth</h1>'
    # @return [String] the rendered component instance
    def to_s
      _erb
    end

    # Render a finished Rack::Response
    # @return [Array] a tuple of [#status, #headers, #to_s]
    def finish
      Rack::Response.new(to_s, status, headers).finish
    end

    # @param [Integer] status an HTTP status code
    # @param [String] body a response body
    # @param [Hash] headers HTTP headers
    # @return [Array] a tuple of [#status, #headers, #to_s]
    def halt(status = 404, body = '', headers = {})
      throw :halt, Rack::Response.new(body, status, headers).finish
    end

    private

    # Evaluate self.render via ERB in the current binding
    # @return [String]
    def _erb
      ERB.new(render.to_s).result(binding)
    end

    # Override render to customize a component
    # @return [#to_s] an object that responds to to_s
    def render
      children
    end

    # render child Components, if there are any
    # @return [#to_s] the rendered output
    def children(scope = self, *args)
      @block ? @block.call(scope, *args) : nil
    end

    # HTTP headers to include in a Rack::Response
    # @return [Hash]
    def headers
      {}
    end

    # A valid HTTP status
    # @return [Integer]
    def status
      200
    end

    # Rack::Component::Memoized is just like Component, only it
    # caches its rendered output in memory and only rerenders
    # when called with new props or a new block
    class Memoized < self
      # instantiate a class-level cache if necessary
      # @return [Rack::Component::ComponentCache] a threadsafe in-memory cache
      def self.cache
        @cache ||= ComponentCache.new
      end

      # @return[String] the rendered component instance from cache,
      # or by executing the erb template when not cached
      def to_s
        memoized { _erb }
      end

      # Check the class-level cache, set it to &block if nil
      # @return [Object] the output of &block.call
      def memoized(&block)
        self.class.cache.fetch(key, &block)
      end

      # a unique key for this component, based on a hash of props & block
      # @return [Integer]
      def key
        [props, block].hash
      end
    end
  end
end
