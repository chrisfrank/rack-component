require 'spec_helper'
require 'rack/component'
require 'pry'

RSpec.describe 'An app composed of Rack::Components' do
  class App < Rack::Component
    # A fake database with a fake 'posts' table
    DB = {
      posts: { 1 => { title: 'Test Post', body: 'Post Body' } }
    }

    # Make request.params available via Rack::Request
    def request
      @req ||= Rack::Request.new(props)
    end

    # Fetch posts, render a layout, then render a post inside the layout,
    # dynamically passing the result of PostFetcher to PostView
    def render
      PostFetcher.new(request.params['id']) do |post|
        Layout.new do
          PostView.new(post)
        end
      end
    end

    # Fetch a post, pass it to the next component
    class PostFetcher < Rack::Component
      def post
        @post ||= DB[:posts].fetch(props.to_i) { halt }
      end

      def render
        children(post)
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

  it 'renders a post when found in the database' do
    get('/posts?id=1') do |res|
      expect(res.body).to include('Test Post')
    end
  end

  it 'renders 404 otherwise' do
    get('/') do |res|
      expect(res.status).to eq(404)
    end
  end
end
