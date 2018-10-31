require 'spec_helper'
require_relative 'fixtures'

RSpec.describe 'An app composed of Rack::Components' do
  # a fake rack app that can catch :halt, like Sinatra or Roda
  class App < Rack::Component
    def self.call(env)
      catch(:halt) { new(env).call }
    end

    def post_id
      props['QUERY_STRING'].match(/\d/).to_s
    end

    # Fetch posts, render a layout, then render a post inside the layout,
    # dynamically passing the result of PostFetcher to PostView
    def render
      [200, {}, [body]]
    end

    def body
      PostFetcher.call(id: post_id) do |post|
        Layout.call do
          %(#{PostView.call(post)}<footer>With a weird footer</footer>)
        end
      end
    end
  end

  class PostFetcher < Rack::Component
    def fetch
      DB[:posts].fetch(props[:id].to_i) { halt }
    end

    def halt
      throw :halt, [404, {}, []]
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
      get('/') { |res| expect(res.status).to eq(404) }
    end
  end
end
