module Rack
  class Component
    class Renderer
      CONFIG = { escape_html: true }.freeze

      def initialize(engine, options = {})
        @config = CONFIG.merge(options)
        require 'tilt'
        require 'erubi' if engine == 'erb'
        heredoc = @config.delete(:template)
        @template = Tilt[engine].new(@config) { heredoc }
      end

      def call(scope, &child)
        @template.render(scope, &child)
      end
    end
  end
end
