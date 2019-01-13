module Rack
  class Component
    # Compile a Tilt template, which a component will render
    class Renderer
      DEFAULT_TILT_OPTIONS = { escape_html: true }.freeze
      FORMATS = %i[erb rhtml erubis haml liquid markdown md mkd].freeze

      def initialize(options = {})
        require 'tilt'
        engine, template, @config = OptionParser.call(options)
        require 'erubi' if engine == 'erb' && @config[:escape_html]
        @template = Tilt[engine].new(@config) { template }
      end

      def call(scope, &child)
        @template.render(scope, &child)
      end

      OptionParser = lambda do |opts|
        tilt_options = DEFAULT_TILT_OPTIONS.merge(opts.delete(:opts) || {})
        engine, template =
          opts.find { |key, _| FORMATS.include?(key) } ||
          [opts[:engine], opts[:template]]

        [engine.to_s, template, tilt_options]
      end

      private_constant :OptionParser
    end
  end
end
