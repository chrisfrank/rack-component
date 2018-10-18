require_relative 'component/cache'
require 'erb'
require 'rack/response'

# Rack::Component is a convenient way of responding to a request
module Rack
  # If React.js had been designed in Ruby, maybe it would look like this
  class Component
    attr_reader :props, :block

    # Handle a Rack request
    # @param [hash] env a rack ENV hash
    # @return [Array] a finished rack tuple
    def self.call(env = {}, &block)
      new(env, &block).to_rack_tuple
    end

    # Render a new Rack::Component as a string
    # @param [Hash] props the properties passed to the component instance
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
    #   MyComponent.render(world: 'Earth') #=> '<h1>Hello Earth</h1>'
    #
    # @return [String] a rendered component instance
    def self.render(props = {}, &block)
      new(props, &block).to_s
    end

    def initialize(props = {}, &block)
      @props = props
      @block = block
    end

    # @return [String] the rendered component instance
    def to_s
      _erb
    end

    # @return [Array] a tuple of [status, header, body],
    # where body is the Component's rendered output
    def to_rack_tuple
      Rack::Response.new(to_s, status, headers).finish
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
    def children
      @block ? @block.call(self) : nil
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

    # Rack::Component::Pure is just like Component, only it
    # caches its rendered output in memory and only rerenders
    # when called with new props or a new block
    class Pure < self
      def self.cache
        @cache ||= Cache.new
      end

      # @return[String] the rendered component instance from cache,
      # or by executing the erb template when not cached
      def to_s
        cached { _erb }
      end

      # Check the class-level cache, set it to &block if nil
      # @return [Object] the output of &block.call
      def cached(&block)
        self.class.cache.get(key, &block)
      end

      # a unique key for this component, based on a hash of props & block
      # @return [Integer]
      def key
        [props, block].hash
      end
    end
  end
end
