require 'spec_helper'

RSpec.describe 'Examples from the README' do
  it 'starts with a plain function' do
    Greeter = lambda do |env|
      "<h1>Hi, #{env[:name]}.</h1>"
    end

    expect(
      Greeter.call(name: 'James')
    ).to eq("<h1>Hi, James.</h1>")
  end

  it 'upgrades to a component for more complex logic' do
    require 'rack/component'

    class FancyGreeter < Rack::Component
      render do |env|
        "<h1>Hi, #{title} #{env[:name]}.</h1>"
      end

      def title
        env[:title] || "President"
      end
    end

    expect(
      FancyGreeter.call(name: 'Macron')
    ).to eq("<h1>Hi, President Macron.</h1>")
    expect(
      FancyGreeter.call(name: 'Merkel', title: 'Chancellor')
    ).to eq("<h1>Hi, Chancellor Merkel.</h1>")
  end

  it 'uses memoized to speed up re-rendering' do
    module Net
      module HTTP
        def self.get(uri); 'President'; end
      end
    end

    class NetworkGreeter < Rack::Component
      render do |env|
        "<h1>Hi, #{title} #{env[:name]}.</h1>"
      end

      def title
        Net::HTTP.get("http://api.heads-of-state.gov/?q=#{env[:name]}")
      end
    end

    expect(
      NetworkGreeter.memoized(name: 'Macron')
    ).to eq("<h1>Hi, President Macron.</h1>")
  end

  describe 'Recipes' do
    it 'renders a list of posts' do
      class PostsList < Rack::Component
        render do |env|
          <<~HTML
            <h1>This is a list of posts</h1>
            <ul>
              #{render_items}
            </ul>
          HTML
        end

        def render_items
          env[:posts].map { |post|
            <<~HTML
              <li class="item">
                <a href="/posts/#{post[:id]}>
                  #{post[:name]}
                </a>
              </li>
            HTML
          }.join
        end
      end

      posts = [{ name: 'First Post', id: 1 }, { name: 'Second', id: 2 }]
      expect(PostsList.call(posts: posts)).to include('First Post')
    end
  end
end
