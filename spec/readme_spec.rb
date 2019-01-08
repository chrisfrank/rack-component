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
      render do
        "<h1>Hi, <%= title %> <%= name %>.</h1>"
      end

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

      # fetch a post from the database and render it inside a layout
      class PostPage < Rack::Component
        def render
          @post = Post.find(env[:id])
          # Nest a PostContent instance inside a Layout instance,
          # with some arbitrary HTML too
          Layout.call(title: @post.title) do
            <<~HTML
              <main>
                #{PostContent.call(title: @post.title, body: @post.body)}
                <footer>
                  I am a footer.
                </footer>
              </main>
            HTML
          end
        end
      end

      class PostContent < Rack::Component
        render do
          <<~ERB
            <article>
              <h1><%= title %></h1>
              <%= body %>
            </article>
          ERB
        end
      end

      class Layout < Rack::Component
        def render
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>#{h env[:title]}</title>
              </head>
              <body>
              #{yield}
              </body>
            </html>
          HTML
        end
      end

      expect(PostPage.call(id: 1)).to include('<h1>Hi</h1>')
    end

    it 'renders a list of posts' do
      class PostsList < Rack::Component
        def render
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
          }.join # unlike JSX, you need to call `join` on your array
        end
      end

      posts = [{ name: 'First Post', id: 1 }, { name: 'Second', id: 2 }]
      expect(PostsList.call(posts: posts)).to include('First Post')
    end

    describe 'with tilt' do
      it 'renders templates via longform config' do
        require 'rack/component'
        require 'tilt'
        require 'erubi'

        class ERBComponent < Rack::Component
          Template = Tilt['erb'].new(escape_html: true) do
            <<~ERB
              <h1>Hi, <%= env[:name] %>.</h1>
            ERB
          end

          def render
            Template.render(self)
          end
        end

        expect(
          ERBComponent.call(name: 'Jim <kirk@starfleet.gov>') { 'hi' }
        ).to eq(
          "<h1>Hi, Jim &lt;kirk@starfleet.gov&gt;.</h1>\n"
        )
      end

      it 'renders ERB via a +render+ macro' do
        class MacroComponent < Rack::Component
          render do
            <<~ERB
              <h1>Hi, <%= name %>.</h1><% binding.pry %>
            ERB
          end
        end

        expect(
          MacroComponent.call(
            name: 'Jim <kirk@starfleet.gov>',
          )
        ).to eq(
          "<h1>Hi, Jim &lt;kirk@starfleet.gov&gt;.</h1>\n"
        )
      end
    end
  end
end
