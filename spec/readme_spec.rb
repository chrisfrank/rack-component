require 'spec_helper'

RSpec.describe 'Examples from the README' do
  it 'starts with a plain function' do
    Greeter = lambda do |env|
      "<h1>Hi, #{env[:name]}.</h1>"
    end

    expect(Greeter.call(name: 'James')).to eq("<h1>Hi, James.</h1>")
  end

  it 'upgrades to a component for more complex logic' do
    require 'rack/component'

    class FormalGreeter < Rack::Component
      render erb: '<h1>Hi, <%= title %> <%= env[:name] %>.</h1>'

      def title
        env[:title] || "Queen"
      end
    end

    expect(
      FormalGreeter.call(name: 'Franklin')
    ).to eq("<h1>Hi, Queen Franklin.</h1>")
    expect(
     FormalGreeter.call(title: 'Captain', name: 'Kirk <kirk@starfleet.gov>')
    ).to eq("<h1>Hi, Captain Kirk &lt;kirk@starfleet.gov&gt;.</h1>")
  end

  describe 'Recipes' do
    it 'Renders one component inside another' do
      Post = Struct.new(:title, :body) do
        def self.find(*); new('Hi', 'Hello'); end
      end

      # Fetch a post from the database and render it inside a Layout
      class PostPage < Rack::Component
        render do |env|
          post = Post.find env[:id]
          # Nest a PostContent instance inside a Layout instance,
          # with some arbitrary HTML too
          Layout.call(title: post.title) do
            <<~HTML
              <main>
                #{PostContent.call(title: post.title, body: post.body)}
                <footer>
                  I am a footer.
                </footer>
              </main>
            HTML
          end
        end
      end

      class Layout < Rack::Component
        # Note that render blocks support Ruby's keyword arguments, and, like
        # any other ruby function, can accept a block.
        #
        # Here, :title is a required key in +env+, while &child
        # is just a regular Ruby block that could be named anything.
        render do |title:, **, &child|
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>
              </head>
              <body>
              #{child.call}
              </body>
            </html>
          HTML
        end
      end

      class PostContent < Rack::Component
        render do |title:, body:, **|
          <<~HTML
            <article>
              <h1>#{h title}</h1>
              #{h body}
            </article>
          HTML
        end
      end

      expect(PostPage.call(id: 1)).to include('<h1>Hi</h1>')
    end

    it 'renders a list of posts' do
      class PostsList < Rack::Component
        render do |posts:, **|
          <<~HTML
            <h1>This is a list of posts</h1>
            <ul>
              #{posts.map { |post| render_item(post) }.join}
            </ul>
          HTML
        end

        def render_item(post)
          <<~HTML
            <li class="item">
              <a href="/posts/#{post[:id]}">
                #{h post[:name]}
              </a>
            </li>
          HTML
        end
      end

      posts = [{ name: 'First Post', id: 1 }, { name: 'Second', id: 2 }]
      expect(PostsList.call(posts: posts)).to include('First Post')
    end

    describe 'with tilt' do
      require 'rack/component'
      require 'tilt'
      require 'erubi'

      it 'renders ERB via a +render+ macro' do
        class MacroComponent < Rack::Component
          render erb: "<h1>Hi, <%= name %>.</h1>"

          def name
            env[:name] || 'jim'
          end
        end

        expect(
          MacroComponent.call(
            name: 'Jim <kirk@starfleet.gov>',
          )
        ).to eq(
          "<h1>Hi, Jim &lt;kirk@starfleet.gov&gt;.</h1>"
        )
      end
    end
  end
end
