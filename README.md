# Rack::Component

Like a React.js component, a `Rack::Component` implements a `render` method that takes input data and returns what to display.

You can combine Components to build complex features out of simple, easily testable units.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-component', require: 'rack/component'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-component

## API Reference
Please see the [YARD docs on rubydoc.info](https://www.rubydoc.info/gems/rack-component)

## Usage

You could build an entire app out of Components, but Ruby already has great HTTP routers like [Roda][roda] and [Sinatra][sinatra]. Here's an example that uses Sinatra for routing, and Components instead of views, controllers, and templates.

### With Sinatra

```ruby
get '/posts/:id' do
  PostFetcher.call(id: params[:id]) do |post|
    Layout.call(title: post[:title]) do
      PostView.call(post)
    end
  end
end
```

_Why_, you may be thinking, _would I write something so ugly when I could write this instead?_

```ruby
get '/posts/:id' do
  @post = Post.find(params[:id])
  @title = @post[:title]
  erb :post
end
```

You'd be right that the traditional version is shorter and pretter. But the Component version’s API is more declarative -- you are describing what you want, and leaving the details of _how to get it_ up to each Component, instead of writing implementation-specific details right in your route block.

The Component version is easier to reuse, refactor, and test. And because Components are meant to be combined via composition, it's actually trivial to make a Component version that's even more concise:

```ruby
get('/posts/:id') do
  PostPageView.call(id: params[:id])
end

# Compose a few Components to save on typing
class PostPageView < Rack::Component
  def render
    PostFetcher.call(id: props[:id]) do |post|
      Layout.call(title: post[:title]) { PostView.call(post) }
    end
  end
end
```

PostFetcher, Layout, and PostView are all simple Rack::Components. Their implementation looks like this:

```ruby
require 'rack/component'

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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/chrisfrank/rack-component.

## License

MIT

[roda]: https://github.com/jeremyevans/roda
[sinatra]: https://github.com/sinatra/sinatra
