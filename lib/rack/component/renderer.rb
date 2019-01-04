module Rack
  class Component
    class Renderer
      def initialize(format = :escaped)
        @format = FORMATS[format] || FORMATS[:escaped]
      end

      def call(component_instance, result)
        return result unless result.is_a?(String)

        @format.call(component_instance, result)
      end

      FORMATS = {
        raw: ->(_comp, result) { result },
        escaped: lambda { |comp, result|
          accessor = Hash.new do |safe_env, key|
            safe_env[key] = comp.h(comp.instance_eval(key.to_s))
          end
          Kernel.format(result, accessor)
        },
      }.freeze
    end
  end
end
