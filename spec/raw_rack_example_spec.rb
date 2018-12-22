require 'spec_helper'
require_relative 'components'

RSpec.describe 'An app composed of Rack::Components' do
  # a fake rack app that can catch :halt, like Sinatra or Roda
  let(:app) do
    Class.new(Rack::Component) do
      # Fetch posts, render a layout, then render a post inside the layout,
      # dynamically passing the result of PostFetcher to PostView
      render do |env|
        catch(:halt) { [200, {}, [body]] }
      end

      def body
        Components::Post.call(id: post_id)
      end

      def post_id
        @env['QUERY_STRING'].match(/\d/).to_s
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

  describe 'without an id' do
    it 'renders 404' do
      get('/posts') { |res| expect(res.status).to eq(404) }
    end
  end
end
