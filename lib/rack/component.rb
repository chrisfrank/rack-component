require_relative 'component/version'
require_relative 'component/memory_cache'
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
        new(env).call env, &child
      end

      # Use +memoized+ instead of +call+ to memoize the result of +call(env)+
      # and return it. Subsequent uses of +memoized(env)+ with the same +env+
      # will be read from a threadsafe in-memory cache, not computed.
      # @example Cache a slow network call
      #   class Fetcher < Rack::Component
      #     render do |env|
      #       Net::HTTP.get(env[:uri]).to_json
      #     end
      #   end
      #
      #   Fetcher.memoized(uri: '/slow/api.json')
      #   # ...
      #   # many seconds later...
      #   # => { some: "data" }
      #
      #   Fetcher.memoized(uri: '/slow/api.json') #=> instant! { some: "data" }
      #   Fetcher.memoized(uri: '/other/source.json') #=> slow again!
      def memoized(env = {}, &child)
        cache.fetch(env.hash) { call(env, &child) }
      end

      # Forget all memoized calls to this component.
      def flush
        cache.flush
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
      def render(&block)
        define_method :call, &block
      end

      # Find or initialize a cache store for a Component class.
      # With no configuration, the store is a threadsafe in-memory cache, capped
      # at 100 keys in length to avoid leaking RAM.
      # @example Use a larger cache instead
      #   class BigComponent < Rack::Component
      #     cache { MemoryCache.new(length: 2000) }
      #   end
      def cache
        @cache ||= (block_given? ? yield : MemoryCache.new(length: 100))
      end
    end

    def initialize(env = {})
      @env = env
    end

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
    #   Useless.call(number: 2) { |env| "the number was #{env[:number]" }
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

    attr_reader :env

    # @example Strip HTML entities from a string
    #   class SafeComponent < Rack::Component
    #     render { |env| h(env[:name]) }
    #   end
    #   SafeComponent.call(name: '<h1>hi</h1>') #=> &lt;h1&gt;hi&lt;/h1&gt;
    def h(obj)
      CGI.escapeHTML(obj.to_s)
    end
  end
end
