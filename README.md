# Rack::Component

Like a React.js component, a `Rack::Component` implements a `render` method that
takes input data and returns what to display.

## Install

Add `rack-component` to your Gemfile and run `bundle install`:

```
gem 'rack-component'
```

## Table of Contents

* [Getting Started](#getting-started)
  * [Components as plain functions](#components-as-plain-functions)
  * [Components as Rack::Components](#components-as-rackcomponents)
  * [Components that re-render instantly](#components-that-re-render-instantly)
* [Recipes](#recipes)
  * [Render one component inside another](#render-one-component-inside-another)
  * [Memoize an expensive component for one minute](#memoize-an-expensive-component-for-one-minute)
  * [Memoize an expensive component until its content changes](#memoize-an-expensive-component-until-its-content-changes)
  * [Render an HTML list from an array](#render-an-html-list-from-an-array)
  * [Render a Rack::Component from a Rails controller](#render-a-rackcomponent-from-a-rails-controller)
  * [Mount a Rack::Component as a Rack app](#mount-a-rackcomponent-as-a-rack-app)
  * [Build an entire App out of Rack::Components](#build-an-entire-app-out-of-rackcomponents)
* [API Reference](#api-reference)
* [Performance](#performance)
* [Compatibility](#compatibility)
* [Anybody using this in production?](#anybody-using-this-in-production)
* [Ruby reference](#ruby-reference)
* [Development](#development)
* [Contributing](#contributing)
* [License](#license)

## Getting Started

### Components as plain functions

The simplest component is just a lambda that takes an `env` parameter:

```ruby
Greeter = lambda do |env|
  "<h1>Hi, #{env[:name]}.</h1>"
end

Greeter.call(name: 'Mina') #=> '<h1>Hi, Mina.</h1>'
```

### Components as Rack::Components

Convert your lambda to a `Rack::Component` when it needs instance methods or
state:

```ruby
require 'rack/component'
class FormalGreeter < Rack::Component
  render do |env|
    "<h1>Hi, #{title} #{env[:name]}.</h1>"
  end

  def title
    # the hash you pass to `call` is available as `env` in instance methods
    env[:title] || "President"
  end
end

FormalGreeter.call(name: 'Macron') #=> "<h1>Hi, President Macron.</h1>"
FormalGreeter.call(name: 'Merkel', title: 'Chancellor') #=> "<h1>Hi, Chancellor Merkel.</h1>"
```

### Components that re-render instantly

Replace `#call` with `#memoized` to make re-renders with the same `env` instant:

```ruby
require 'rack/component'
require 'net/http'
class NetworkGreeter < Rack::Component
  render do |env|
    "Hi, #{get_job_title_from_api} #{env[:name]}."
  end

  def get_job_title_from_api
    endpoint = URI("http://api.heads-of-state.gov/")
    Net::HTTP.get("#{endpoint}?q=#{env[:name]}")
  end
end

NetworkGreeter.memoized(name: 'Macron')
# ...after a slow network call to our fictional Heads Of State API
#=> "Hi, President Macron."

NetworkGreeter.memoized(name: 'Macron') # subsequent calls with the same env are instant.
#=> "Hi, President Macron."

NetworkGreeter.memoized(name: 'Merkel')
# ...this env is new, so NetworkGreeter makes another network call
#=> "Hi, Chancellor Merkel."

NetworkGreeter.memoized(name: 'Merkel') #=> instant! "Hi, Chancellor Merkel."
NetworkGreeter.memoized(name: 'Macron') #=> instant! "Hi, President Macron."
```

## Recipes

### Render one component inside another

You can nest Rack::Components as if they were [React Children][jsx children] by
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
    # Nest a PostContent instance inside a Layout instance, with some arbitrary HTML too
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

### Memoize an expensive component for one minute

You can use `memoized` as a time-based cache by passing a timestamp to `env`:

```ruby
require 'rack/component'

# Render one million posts as JSON
class MillionPosts < Rack::Component
  render { |env| Post.limit(1_000_000).to_json }
end

MillionPosts.memoized(Time.now.to_i / 60) #=> first call is slow
MillionPosts.memoized(Time.now.to_i / 60) #=> next calls in same minute are quick
```

### Memoize an expensive component until its content changes

This recipe will speed things up when your database calls are fast but your
render method is slow:

```ruby
require 'rack/component'
class PostAnalysis < Rack::Component
  render do |env|
    <<~HTML
      <h1>#{env[:post].title}</h1>
      <article>#{env[:post].content}</article>
      <aside>#{expensive_natural_language_analysis}</aside>
    HTML
  end

  def expensive_natural_language_analysis
    FancyNaturalLanguageLibrary.analyze(env[:post].content)
  end
end

PostAnalysis.memoized(post: Post.find(1)) #=> slow, because it runs an expensive natural language analysis
PostAnalysis.memoized(post: Post.find(1)) #=> instant, because the content of :post has not changed
```

This recipe works with any Ruby object that implements a `#hash` method based
on the object's content, including instances of `ActiveRecord::Base` and
`Sequel::Model`.

### Render an HTML list from an array

[JSX Lists][jsx lists] use JavaScript's `map` function. Rack::Component does
likewise, only you need to call `join` on the array:

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
          <a href="#{post[:url]}">
            #{post[:name]}
          </a>
        </li>
      HTML
    }.join #unlike JSX, you need to call `join` on your array
  end
end

posts = [{ name: 'First Post', id: 1 }, { name: 'Second', id: 2 }]
PostsList.call(posts: posts) #=> <h1>This is a list of posts</h1> <ul>...etc
```

### Render a Rack::Component from a Rails controller

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    render json: PostsList.call(params)
  end
end

# app/components/posts_list.rb
class PostsList < Rack::Component
  render { |env| posts.to_json }

  def posts
    Post.magically_filter_via_params(env)
  end
end
```

### Mount a Rack::Component as a Rack app

Because Rack::Components follow the same API as a Rack app, you can mount them
anywhere you can mount a Rack app. It's up to you to return a valid rack
tuple, though.

```ruby
# config.ru
require 'rack/component'

class Posts < Rack::Component
  render do |env|
    [status, headers, [body]]
  end

  def status
    200
  end

  def headers
    { 'Content-Type' => 'application/json' }
  end

  def body
    Post.all.to_json
  end
end

run Posts
```

### Build an entire App out of Rack::Components

In real life, maybe don't do this. Use [Roda] or [Sinatra] for routing, and use
Rack::Component instead of Controllers, Views, and templates. But to see an
entire app built only out of Rack::Components, see
[the example spec](https://github.com/chrisfrank/rack-component/blob/master/spec/raw_rack_example_spec.rb).

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

Notice that using `Component#memoized` is _slower_ than using `Component#call`
in this benchmark. Because these components do almost nothing, it's more work to
check the memoziation cache than to just render. For components that don't
access a database, don't do network I/O, and aren't very CPU-intensive, it's
probably fastest not to memoize. For components that do I/O, using `#memoize`
can speed things up by several orders of magnitude.

## Compatibility

Rack::Component has zero dependencies, and will work in any Rack app. It should
even work _outside_ a Rack app, because it's not actually dependent on Rack. I
packaged it under the Rack namespace because it follows the Rack `call`
specification, and because that's where I use and test it.

## Anybody using this in production?

Aye:

- [future.com](https://www.future.com/)
- [Seattle & King County Homelessness Response System](https://hrs.kc.future.com/)

## Ruby reference

Where React uses [JSX] to make components more ergonomic, Rack::Component leans
heavily on some features built into the Ruby language, specifically:

- [Heredocs]
- [String Interpolation]
- [Calling methods with a block][ruby blocks]

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
[jsx]: https://reactjs.org/docs/introducing-jsx.html
[jsx children]: https://reactjs.org/docs/composition-vs-inheritance.html
[jsx lists]: https://reactjs.org/docs/lists-and-keys.html
[heredocs]: https://ruby-doc.org/core-2.5.0/doc/syntax/literals_rdoc.html#label-Here+Documents
[string interpolation]: http://ruby-for-beginners.rubymonstas.org/bonus/string_interpolation.html
[ruby blocks]: https://mixandgo.com/learn/mastering-ruby-blocks-in-less-than-5-minutes
[roda]: http://roda.jeremyevans.net
[sinatra]: http://sinatrarb.com
