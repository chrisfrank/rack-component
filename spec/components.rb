module Components
  # Find and render a post matching the given id
  class Post < Rack::Component
    def initialize(id:)
      @id = id
    end

    def render
      post = PostFetcher.call(id: @id)
      Layout.call(title: post[:title]) { PostView.call(post) }
    end
  end

  # Fetch a post, pass it to the next component
  class PostFetcher < Rack::Component
    def initialize(id:)
      @id = id.to_i
      @post = DB[:posts].find { |post| post[:id] == @id } || halt
    end

    def render
      @post
    end

    def halt
      throw :halt, [404, {}, []]
    end
  end

  # A fake database with a fake 'posts' table
  DB = { posts: [{ id: 1, title: 'Example Title', body: 'Example body' }] }

  # View a single post
  class PostView < Rack::Component
    def initialize(title:, body:, **)
      @title = title
      @body = body
    end

    def render
      <<~HTML
        <article>
          <h1>#{@title}</h1>
          <p>#{@body}</h1>
        </article>
      HTML
    end
  end

  class Layout < Rack::Component
    def initialize(title: '')
      @title = title
    end

    def render
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>#{@title}</title>
          </head>
          <body>
            #{yield}
          </body>
        </html>
      HTML
    end
  end
end
