module Rack
  class Component
    class Template
      CONFIG = { format: :erb, escape_html: true }.freeze

      def initialize(format, options = {}, block)
        require 'tilt'
        config = CONFIG.merge(options)
        format = config.delete(:format)
        require 'erubi' if format == 'erb' && config[:escape_html]
        @template = Tilt[format.to_s].new(config) do
          Stub.instance_exec(&block)
        end
      end

      def render(scope, &child)
        @template.render(scope, scope.env, &child)
      end

      module Stub
        def self.before
          nil
        end
      end
    end
  end
end
