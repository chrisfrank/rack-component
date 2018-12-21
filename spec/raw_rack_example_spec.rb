require 'spec_helper'
require_relative 'components'

RSpec.describe 'An app composed of Rack::Components' do
  # a fake rack app that can catch :halt, like Sinatra or Roda
  let(:app) do
    Class.new(Rack::Component) do
      def self.call(env)
        catch(:halt) { super }
      end

      def initialize(env)
        @env = env
      end

      def post_id
        @env['QUERY_STRING'].match(/\d/).to_s
      end

      # Fetch posts, render a layout, then render a post inside the layout,
      # dynamically passing the result of PostFetcher to PostView
      def render
        [200, {}, [body]]
      end

      def body
        Components::Post.call(id: post_id)
      end
    end
  end

  describe 'with a valid id param' do
    it 'renders a post' do
      get('/posts?id=1') do |res|
        expect(res.body).to include('Example Title')
        expect(res.body).to include('DOCTYPE')
      end
    end
  end

  describe 'without an id param' do
    it 'renders 404' do
      get('/') { |res| expect(res.status).to eq(404) }
    end
  end
end
