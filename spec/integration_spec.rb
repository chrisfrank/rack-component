require 'spec_helper'
require 'rack/component'
require 'pry'

RSpec.describe 'An app composed of Rack::Components' do
  # a fake rack app that can catch :halt, like Sinatra or Roda
  class App
    # A fake database with a fake 'posts' table
    DB = { posts: { 1 => { title: 'Test Post', body: 'Post Body' } } }

    def self.call(env)
      catch(:halt) do
        new(env).render
      end
    end

    def initialize(env)
      @request = Rack::Request.new(env)
    end

    # Fetch posts, render a layout, then render a post inside the layout,
    # dynamically passing the result of PostFetcher to PostView
    def render
      [
        200,
        {},
        PostFetcher.call(@request.params['id']) do |post|
          Layout.call do
            %(
              #{PostView.call(post)}
              <footer>With a weird footer</footer>
            )
          end
        end
      ]
    end

    # Fetch a post, pass it to the next component
    class PostFetcher < Rack::Component
      def post
        DB[:posts].fetch(props.to_i) { halt }
      end

      def render
        children(post)
      end

      def halt
        throw :halt, [404, {}, []]
      end
    end

    class Layout < Rack::Component
      def render
        %(
          <!DOCTYPE html>
            <html>
            <head>
              <title>Rack::Compoment</title>
            </head>
            <body>
              #{children}
            </body>
          </html>
        )
      end
    end

    class PostView < Rack::Component
      def render
        %(<article>#{props[:title]}</article>)
      end
    end
  end

  let(:app) { App }

  describe 'with a valid id param' do
    it 'renders a post when found in the database' do
      get('/posts?id=1') { |res| expect(res.body).to include('Test Post') }
    end

    it 'can render arbitrary blocks of text' do
      get('/posts?id=1') { |res| expect(res.body).to include('Test Post') }
    end
  end

  describe 'without an id param' do
    it 'renders 404' do
      get('/') do |res|
        expect(res.status).to eq(404)
      end
    end
  end
end
