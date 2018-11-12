# render an HTML page
class Layout < Rack::Component
  def render
    %(
      <html>
        <head>
          <title>#{props[:title]}</title>
        </head>
        <body>
          #{yield}
        </body>
      </html>
    )
  end
end

# Fetch a post, pass it to the next component
class PostFetcher < Rack::Component
  def render
    yield fetch
  end

  def fetch
    DB[:posts].fetch(props[:id].to_i)
  end
end

# A fake database with a fake 'posts' table
DB = { posts: { 1 => { title: 'Example Title', body: 'Example body' } } }

# View a single post
class PostView < Rack::Component
  def render
    %(
      <article>
        <h1>#{props[:title]}</h1>
        <p>#{props[:body]}</h1>
      </article>
    )
  end
end
