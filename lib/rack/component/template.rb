module Rack
  class Component
    class Template
      CONFIG = { escape_html: true }.freeze

      def initialize(format, options, &block)
        config = CONFIG.merge(options)
        require 'tilt'
        require 'erubi' if format == :erb && config[:escape_html]
        @template = Tilt[format.to_s].new(config, &block)
      end

      def render(scope, &child)
        @template.render(scope, scope.env, &child)
      end
    end
  end
end
