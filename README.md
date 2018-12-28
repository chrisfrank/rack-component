# Rack::Component

Like a React.js component, a `Rack::Component` implements a `render` method that
takes input data and returns what to display.

## In your Gemfile:
```ruby
gem 'rack-component', require: 'rack/component'
```

## Getting Started

The simplest component is just a function:
```ruby
Greeter = lambda do |env|
  "<h1>Hello, #{env[:name]}.</h1>"
end

Greeter.call(name: 'Mina') #=> '<h1>Hello, Mina.</h1>'
```

Convert your function to a `Rack::Component` when it needs instance methods or state:
```ruby
require 'rack/component'

class FormalGreeter < Rack::Component
  render do |env|
    "<h1>Hello, #{title} #{env[:name]}.</h1>"
  end

  def title
    # the hash you pass to `call` is available as `env` in
    # your component's instance methods
    env[:title] || "President"
  end
end

FancyGreeter.call(name: 'Macron') #=> "<h1>Hello, President Macron.</h1>"
FancyGreeter.call(name: 'Merkel', title: 'Chancellor') #=> "<h1>Hello, Chancellor Merkel.</h1>"
```

Replace `#call` with `#memoized` to make re-renders instant:
```ruby
require 'rack/component'
require 'net/http'
class NetworkGreeter < Rack::Component
  render do |env|
    "Hello, #{get_job_title_from_api} #{env[:name]}."
  end

  def get_job_title_from_api
    endpoint = URI("http://api.heads-of-state.gov/")
    Net::HTTP.get("#{endpoint}?q=#{env[:name]}")
  end
end

NetworkGreeter.memoized(name: 'Macron')
# ...after a slow network call to our fictional Heads Of State API
#=> "Hello, President Macron."

NetworkGreeter.memoized(name: 'Macron') # subsequent calls with the same env are instant.
#=> "Hello, President Macron."

NetworkGreeter.memoized(name: 'Merkel')
# ...this env is new, so NetworkGreeter makes another network call
#=> "Hello, Chancellor Merkel."

NetworkGreeter.memoized(name: 'Merkel') #=> instant! "Hello, Chancellor Merkel."
NetworkGreeter.memoized(name: 'Macron') #=> instant! "Hello, President Macron."
```

## Recipes

### Render one component inside another
You can nest Rack::Components as if they were [React Children][JSX Children] by
calling them with a block.
```ruby
Layout.call(title: 'Home') { Content.call }
```

Here's a more fully fleshed example:
```ruby
require 'rack/component'

# let's say this is a Sinatra app:
get '/posts/:id' do
  PostPage.call(id: params[:id])
end

# fetch a post from the database and render it inside a layout
class PostPage < Rack::Component
  render do |env|
    post = Post.find(id: env[:id])
    # Nest a PostView inside a Layout
    Layout.call(title: post.title) do
      PostContent.call(title: post.title, body: post.body)
    end
  end
end

class PostContent < Rack::Component
  render do |env|
    <<~HTML
      <article>
        <h1>#{env[:title]}</h1>
        #{env[:body]}
      </article>
    HTML
  end
end

class Layout < Rack::Component
  render do |env, &children|
    # the `&children` param is just a standard ruby block
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>#{env[:title]}</title>
        </head>
        <body>
          #{children.call}
        </body>
      </html>
    HTML
  end
end
```

### Render an HTML list from an array
[JSX Lists] use JavaScript's `map` function. Rack::Component does likewise.

```ruby
require 'rack/component'
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
          <a href="#{post[:url]}>
            #{post[:name]}
          </a>
        </li>
      HTML
    }.join
  end
end

posts = [{ name: 'First Post', id: 1 }, { name: 'Second', id: 2 }]
PostsList.call(posts: posts) #=> <h1>This is a list of posts</h1> <ul>...etc
```

### Mount a Rack::Component tree inside a Rails app
```ruby
# config/routes.rb
mount MyComponent, at: '/a_path_of_your_choosing'

# config/initializers/my_component.rb
require 'rack/component'
class MyComponent < Rack::Component
  render do |env|
    <<~HTML
      <h1>Hello from inside a Rails app!</h1>
    HTML
  end
end

## API Reference
The full API reference is available here:

https://www.rubydoc.info/gems/rack-component

For info on how to clear or change the size of the memoziation cache, please see
[the spec][spec].

## Performance
On my machine, Rendering a Rack::Component is almost 10x faster than rendering a
comparable Tilt template, and almost 100x faster than ERB from the Ruby standard
library. Run `ruby spec/benchmarks.rb` to see what to expect in your env.

```
$ ruby spec/benchmarks.rb
Warming up --------------------------------------
     Ruby stdlib ERB     2.807k i/100ms
       Tilt (cached)    28.611k i/100ms
              Lambda   249.958k i/100ms
           Component   161.176k i/100ms
Component [memoized]    94.586k i/100ms
Calculating -------------------------------------
     Ruby stdlib ERB     29.296k (± 2.0%) i/s -    148.771k in   5.080274s
       Tilt (cached)    319.935k (± 2.8%) i/s -      1.602M in   5.012009s
              Lambda      6.261M (± 1.2%) i/s -     31.495M in   5.031302s
           Component      2.773M (± 1.8%) i/s -     14.022M in   5.057528s
Component [memoized]      1.276M (± 0.9%) i/s -      6.432M in   5.041348s
```

Notice that using `Component#memoized` is *slower* than using `Component#call`
in this benchmark. Because these components do almost nothing, it's more work to
check the memoziation cache than to just render. For components that don't
access a database, don't do network I/O, and aren't very CPU-intensive, it's
probably fastest not to memoize. For components that do I/O, using `#memoize`
can speed things up by several orders of magnitude.

## Anybody using this in production?

Aye:

- [future.com](https://www.future.com/)
- [Seattle & King County Homelessness Response System](https://hrs.kc.future.com/)

## Ruby reference:

Where React uses [JSX] to make components more ergonomic, Rack::Component
uses the ergonomics built into Ruby, specifically:

- [Heredocs]
- [String Interpolation]
- [Calling methods with a block][Ruby Blocks]

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

[spec]: https://github.com/chrisfrank/rack-component/blob/master/spec/rack/component_spec.rb
[JSX]: https://reactjs.org/docs/introducing-jsx.html
[JSX Children]: https://reactjs.org/docs/composition-vs-inheritance.html
[JSX Lists]: https://reactjs.org/docs/lists-and-keys.html
[Heredocs]: https://ruby-doc.org/core-2.5.0/doc/syntax/literals_rdoc.html#label-Here+Documents
[String Interpolation]: http://ruby-for-beginners.rubymonstas.org/bonus/string_interpolation.html
[Ruby Blocks]: https://mixandgo.com/learn/mastering-ruby-blocks-in-less-than-5-minutes
