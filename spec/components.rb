module Components
  # Find and render a post matching the given id
  class Post < Rack::Component
    render do
      Layout.call(title: record[:title]) do
        PostView.call(record) do
          next_post = PostFetcher.call(id: record[:id] + 1)
          "Further reading: #{next_post[:title]}"
        end
      end
    end

    def record
      @record ||= PostFetcher.call(id: env[:id].to_i) || halt
    end

    def halt
      throw :halt, [404, {}, []]
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
    render do |env|
      <<~HTML
        <article>
          <h1>#{env[:title]}</h1>
          <p>#{env[:body]}</h1>
          <footer>
            #{children}
          </footer>
        </article>
      HTML
    end
  end

  class Layout < Rack::Component
    render do
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>#{env[:title]}</title>
          </head>
          <body>
            #{children}
          </body>
        </html>
      HTML
    end
  end
end
