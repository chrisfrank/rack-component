require_relative 'component/version'
require_relative 'component/template'
require 'cgi'

module Rack
  # Subclass Rack::Component to compose functional, declarative responses to
  # HTTP requests.
  class Component
    class << self
      # Instantiate a new component with given +env+ return its rendered output.
      # @example Render a child block inside an HTML document
      #   class Layout < Rack::Component
      #     render do |env, &child|
      #       <<~HTML
      #         <!DOCTYPE html>
      #         <html>
      #           <head>
      #             <title>#{env[:title]}</title>
      #           </head>
      #           <body>#{child.call}</body>
      #         </html>
      #       HTML
      #     end
      #   end
      #
      #   Layout.call(title: 'Hello') { "<h1>Hello from Rack::Component" } #=>
      #   # <!DOCTYPE html>
      #   # <html>
      #   #   <head>
      #   #     <title>Hello</title>
      #   #   </head>
      #   #   <body><h1>Hello from Rack::Component</h1></body>
      #   # </html>
      def call(env = {}, &child)
        new(env).render(&child)
      end

      def render(format = :erb, options = {}, &block)
        template = Template.new(format, options, &block)
        define_method :render do |&child|
          template.render(self, &child)
        end
      end
    end

    def initialize(env = {})
      @env = env
    end

    # Out of the box, a +Rack::Component+ just returns whatever +env+ you call
    # it with, or yields with +env+ if you call it with a block.
    # Override +render+ to make your component do something useful.
    #
    # @example a useless component
    #   Useless = Class.new(Rack::Component)
    #   Useless.call(number: 1) #=> { number: 1 }
    #   Useless.call(number: 2) #=> { number: 2 }
    #   Useless.call(number: 2) { |env| "the number was #{env[:number]" }
    #   #=> 'the number was 2'
    #
    # @example a component that says hello, escaping output via #h
    #   class Greeter < Rack::Component
    #     def render
    #       "Hi, #{h env[:name]}"
    #     end
    #   end
    #
    #   Greeter.call(name: 'Jim') #=> 'Hi, Jim'
    #   Greeter.call(
    #     name: 'Bones <mccoy@starfleet.gov>'
    #   ) #=> 'Hi, Bones &lt;mccoy@starfleet.gov&gt;'
    def render
      block_given? ? yield(env) : env
    end

    def to_s
      render.to_s
    end

    def env
      @env || {}
    end

    # @example Strip HTML entities from a string
    #   class SafeComponent < Rack::Component
    #     render { h env[:name] }
    #   end
    #   SafeComponent.call(name: '<h1>hi</h1>') #=> &lt;h1&gt;hi&lt;/h1&gt;
    def h(obj)
      CGI.escapeHTML(obj.to_s)
    end
  end
end
