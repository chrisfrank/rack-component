require_relative 'component/version'
require_relative 'component/renderer'
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
      #             <title>%{env[:title]}</title>
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
        new(env).call(&child)
      end

      # Use a +render+ block define what a component will do when you +call+ it.
      # @example Say hello
      #   class Greeter < Rack::Component
      #     render do |env|
      #       "Hi, #{env[:name]}"
      #     end
      #   end
      #
      #   Greeter.call(name: 'Jim') #=> 'Hi, Jim'
      #   Greeter.call(name: 'Bones') #=> 'Hi, Bones'
      def render(format = :escaped, &block)
        renderer = Renderer.new(format)
        define_method :_raw, &block
        private :_raw
        define_method :call do |&child|
          renderer.call(self, _raw(env, &child))
        end
      end
    end

    def initialize(env = {})
      @env = env
    end

    attr_reader :env

    # Out of the box, a +Rack::Component+ just returns whatever +env+ you call
    # it with, or yields with +env+ if you call it with a block.
    # Use a class-level +render+ block when wiriting your Components to override
    # this method with more useful behavior.
    # @see Rack::Component#render
    #
    # @example a useless component
    #   Useless = Class.new(Rack::Component)
    #   Useless.call(number: 1) #=> { number: 1 }
    #   Useless.call(number: 2) #=> { number: 2 }
    #   Useless.call(number: 2) { |env| "the number was %{env[:number]}" }
    #   #=> 'the number was 2'
    #
    # @example a useful component
    #   class Greeter < Rack::Component
    #     render do |env|
    #       "Hi, #{env[:name]}"
    #     end
    #   end
    #
    #   Greeter.call(name: 'Jim') #=> 'Hi, Jim'
    #   Greeter.call(name: 'Bones') #=> 'Hi, Bones'
    def call(*)
      block_given? ? yield(env) : env
    end

    # @return [String] the param as a string, with HTML characters escaped
    def h(obj)
      CGI.escapeHTML(obj.to_s)
    end
  end
end
