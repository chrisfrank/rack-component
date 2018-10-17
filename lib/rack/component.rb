require_relative 'component/version'
require 'erb'

module Rack
  # Render a chain of components
  class Component
    # If your Component’s template does not require dynamic interpolation,
    # you can declare it as a class-level constant.
    TEMPLATE = %(<%= children %>).freeze

    attr_reader :props

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
    #   MyComponent.call(world: 'Earth') #=> '<h1>Hello Earth</h1>'
    def self.call(props = {}, &block)
      new(props, &block).to_s
    end

    def initialize(props = {}, &block)
      @props = props
      @children = block
    end

    # @return [String] the rendered component
    def to_s
      ERB.new(_render).result(binding)
    end

    private

    def _render
      render.to_s
    end

    # Override render to customize a component
    # @return [String] the rendered output
    def render
      self.class.const_get(:TEMPLATE)
    end

    # Yield to the next block, if called
    def children
      @children ? @children.call(self) : nil
    end
  end
end
