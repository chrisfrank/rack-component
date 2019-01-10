require_relative 'component/version'
require_relative 'component/renderer'
require 'cgi'

module Rack
  # Subclass Rack::Component to compose functional, declarative responses to
  # HTTP requests.
  # @example Subclass Rack::Component to compose functional, declarative
  # responses to HTTP requests.
  #   class Greeter < Rack::Component
  #     render { "Hi, #{env[:name]" }
  #   end
  class Component
    # @example If you don't want to subclass, you can extend
    # Rack::Component::Methods instead.
    #   class POROGreeter
    #     extend Rack::Component::Methods
    #     render { "Hi, #{env[:name]" }
    #   end
    module Methods
      def self.extended(base)
        base.include(InstanceMethods)
        base.define_method(:initialize) { |env| @env = env }
      end

      def render(opts = {})
        block_given? ? configure_block(Proc.new) : configure_template(opts)
      end

      def call(env = {}, &children)
        new(env).render(&children)
      end

      # Instances of Rack::Component come with these methods.
      module InstanceMethods
        # +env+ is Rack::Component's version of React's +props+ hash.
        def env
          @env || {}
        end

        # +h+ removes HTML characters from strings via +CGI.escapeHTML+.
        def h(obj)
          CGI.escapeHTML(obj.to_s)
        end
      end

      private

      # :reek:TooManyStatements
      # :reek:DuplicateMethodCall
      def configure_block(block)
        # Convert the block to an instance method, because instance_exec
        # doesn't allow passing an &child param, and because it's faster.
        define_method :_rc_render, &block
        private :_rc_render

        # Now that the block is a method, it must be called with the correct
        # number of arguments. Ruby's +arity+ method is unreliable when keyword
        # args are involved, so we count arity by hand.
        arity = block.parameters.reject { |type, _| type == :block }.length

        # Reek hates this DuplicateMethodCall, but fixing it would mean checking
        # arity at runtime, rather than when the render macro is called.
        if arity.zero?
          define_method(:render) { |&child| _rc_render(&child) }
        else
          define_method(:render) { |&child| _rc_render(env, &child) }
        end
      end

      def configure_template(options)
        renderer = Renderer.new(options)
        define_method(:render) { |&child| renderer.call(self, &child) }
      end
    end

    extend Methods
  end
end
