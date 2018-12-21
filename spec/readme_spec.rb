require 'spec_helper'

RSpec.describe 'the example from the README' do
  let(:docs) do
    require 'rack/component'

    # Make a network request and return the response
    class Fetcher < Rack::Component
      require 'net/http'
      def initialize(uri:)
        @response = Net::HTTP.get(URI(uri))
      end

      def render
        yield @response
      end
    end

    # Parse items from a JSON Feed document
    class JSONFeedParser < Rack::Component
      require 'json'
      def initialize(data)
        @items = JSON.parse(data).fetch('items')
      end

      def render
        yield @items
      end
    end

    # Render an HTML list of posts
    class PostsList < Rack::Component
      def initialize(posts:, style: '')
        @posts = posts
        @style = style
      end

      def render
        <<~HTML
          <ul style="#{@style}">
            #{@posts.map(&ListItem).join}"
          </ul>
        HTML
      end

      ListItem = ->(post) { "<li>#{post['title']}</li>" }
    end

    # Fetch JSON Feed data from daring fireball, parse it, render a list
    Fetcher.call(uri: 'https://daringfireball.net/feeds/json') do |data|
      JSONFeedParser.call(data) do |items|
        PostsList.call(posts: items, style: 'background-color: red')
      end
    end
  end

  it('works') { expect(docs).to include('<ul style="background-color: red">') }
end
