require 'spec_helper'

RSpec.describe 'An app composed of Rack::Components' do
  # a fake rack app that can catch :halt, like Sinatra or Roda
  let(:app) do
    Class.new(Rack::Component) do
      # Fetch posts, render a layout, then render a post inside the layout,
      # dynamically passing the result of PostFetcher to PostView
      render do |env|
        [200, {}, [body]]
      end

      def body
        post_id ? Components::Post.call(id: post_id) : Components::List.call
      end

      def post_id
        env['QUERY_STRING'].match(/\d/).to_s
      end
    end
  end

  describe 'with a valid id param' do
    let(:res) { get('/posts?id=1') }
    it 'renders a post' do
      expect(res.body).to include('Example Title')
      expect(res.body).to include('DOCTYPE')
    end
  end

  describe 'without an id' do
    let(:res) { get('/posts') }
    it 'lists posts' do
      expect(res.body).to include('<ul>')
    end
  end
end

module Components
  # Find and render a post matching the given id
  class Post < Rack::Component
    render do |env|
      Layout.call(title: record[:title]) do
        PostView.call(record) do
          next_post = PostFetcher.call(id: record[:id] + 1)
          next_post && "Further reading: #{next_post[:title]}"
        end
      end
    end

    def record
      PostFetcher.call(id: env[:id].to_i)
    end
  end

  # Fetch a post, pass it to the next component
  PostFetcher = ->(id:) { DB[:posts].find { |post| post[:id] == id } }

  # A fake database with a fake 'posts' table
  DB = {
    posts: [
      { id: 1, title: 'Example Title', body: 'Example body' },
      { id: 2, title: 'Meh', body: 'Example body' },
    ]
  }

  # View a single post
  class PostView < Rack::Component
    render do |env, &children|
      <<~HTML
        <article>
          <h1>%{env[:title]}</h1>
          <p>%{env[:body]}</h1>
          <footer>
            #{children&.call}
          </footer>
        </article>
      HTML
    end
  end

  class Layout < Rack::Component
    render do |env, &children|
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>%{env[:title]}</title>
          </head>
          <body>
            #{children.call}
          </body>
        </html>
      HTML
    end
  end
end
