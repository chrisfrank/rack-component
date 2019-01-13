# Rack::Component

Like a React.js component, a `Rack::Component` implements a `render` method that
takes input data and returns what to display. You can use Components instead of
Controllers, Views, Templates, and Helpers, in any Rack app.

## Install

Add `rack-component` to your Gemfile and run `bundle install`:

```
gem 'rack-component'
```

## Quickstart with Sinatra

```ruby
# config.ru
require 'sinatra'
require 'rack/component'

class Hello < Rack::Component
  render do |env|
    "<h1>Hello, #{h env[:name]}</h1>"
  end
end

get '/hello/:name' do
  Hello.call(name: params[:name])
end

run Sinatra::Application
```

**Note that Rack::Component does not escape strings by default**. To escape
strings, you can either use the `#h` helper like in the example above, or you
can configure your components to render a template that escapes automatically.
See the [Recipes](#recipes) section for details.

## Table of Contents

* [Getting Started](#getting-started)
  * [Components as plain functions](#components-as-plain-functions)
  * [Components as Rack::Components](#components-as-rackcomponents)
    * [Components if you hate inheritance](#components-if-you-hate-inheritance)
* [Recipes](#recipes)
  * [Render one component inside another](#render-one-component-inside-another)
  * [Render a template that escapes output by default via Tilt](#render-a-template-that-escapes-output-by-default-via-tilt)
  * [Render an HTML list from an array](#render-an-html-list-from-an-array)
  * [Render a Rack::Component from a Rails controller](#render-a-rackcomponent-from-a-rails-controller)
  * [Mount a Rack::Component as a Rack app](#mount-a-rackcomponent-as-a-rack-app)
  * [Build an entire App out of Rack::Components](#build-an-entire-app-out-of-rackcomponents)
  * [Define `#render` at the instance level instead of via `render do`](#define-render-at-the-instance-level-instead-of-via-render-do)
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

Upgrade your lambda to a `Rack::Component` when it needs HTML escaping, instance
methods, or state:

```ruby
require 'rack/component'
class FormalGreeter < Rack::Component
  render do |env|
    "<h1>Hi, #{h title} #{h env[:name]}.</h1>"
  end

  # +env+ is available in instance methods too
  def title
    env[:title] || "Queen"
  end
end

FormalGreeter.call(name: 'Franklin') #=> "<h1>Hi, Queen Franklin.</h1>"
FormalGreeter.call(
  title: 'Captain',
  name: 'Kirk <kirk@starfleet.gov>'
) #=> <h1>Hi, Captain Kirk &lt;kirk@starfleet.gov&gt;.</h1>
```

#### Components if you hate inheritance

Instead of inheriting from `Rack::Component`, you can `extend` its methods:

```ruby
class SoloComponent
  extend Rack::Component::Methods
  render { "Family is complicated" }
end
```

## Recipes

### Render one component inside another

You can nest Rack::Components as if they were [React Children][jsx children] by
calling them with a block.

```ruby
Layout.call(title: 'Home') do
  Content.call
end
```

Here's a more fully fleshed example:

```ruby
require 'rack/component'

# let's say this is a Sinatra app:
get '/posts/:id' do
  PostPage.call(id: params[:id])
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
  # The +render+ macro supports Ruby's keyword arguments, and, like any other
  # Ruby function, can accept a block via the & operator.
  # Here, :title is a required key in +env+, and &child is just a regular Ruby
  # block that could be named anything.
  render do |title:, **, &child|
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>#{h title}</title>
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
```

### Render a template that escapes output by default via Tilt

If you add [Tilt][tilt] and `erubi` to your Gemfile, you can use the `render`
macro with an automatically-escaped template instead of a block.

```ruby
# Gemfile
gem 'tilt'
gem 'erubi'
gem 'rack-component'

# my_component.rb
class TemplateComponent < Rack::Component
  render erb: <<~ERB
    <h1>Hello, <%= name %></h1>
  ERB

  def name
    env[:name] || 'Someone'
  end
end

TemplateComponent.call #=> <h1>Hello, Someone</h1>
TemplateComponent.call(name: 'Spock<>') #=> <h1>Hello, Spock&lt;&gt;</h1>
```

Rack::Component passes `{ escape_html: true }` to Tilt by default, which enables
automatic escaping in ERB (via erubi) Haml, and Markdown. To disable automatic
escaping, or to pass other tilt options, use an `opts: {}` key in `render`:

```ruby
class OptionsComponent < Rack::Component
  render opts: { escape_html: false, trim: false }, erb: <<~ERB
    <article>
      Hi there, <%= {env[:name] %>
      <%== yield %>
    </article>
  ERB
end
```

Template components support using the `yield` keyword to render child
components, but note the double-equals `<%==` in the example above. If your
component escapes HTML, and you're yielding to a component that renders HTML,
you probably want to disable escaping via `==`, just for the `<%== yield %>`
call. This is safe, as long as the component you're yielding to uses escaping.

Using `erb` as a key for the inline template is a shorthand, which also works
with `haml` and `markdown`. But you can also specify `engine` and `template`
explicitly.

```ruby
require 'haml'
class HamlComponent < Rack::Component
  # Note the special HEREDOC syntax for inline Haml templates! Without the
  # single-quotes, Ruby will interpret #{strings} before Haml does.
  render engine: 'haml', template: <<~'HAML'
    %h1 Hi #{env[:name]}.
  HAML
end
```

Using a template instead of raw string interpolation is a safer default, but it
can make it less convenient to do logic while rendering. Feel free to override
your Component's `#initialize` method and do logic there:

```ruby
class EscapedPostView < Rack::Component
  def initialize(env)
    @post = Post.find(env[:id])
    # calling `super` will populate the instance-level `env` hash, making
    # `env` available outside this method. But it's fine to skip it.
    super
  end

  render erb: <<~ERB
    <article>
      <h1><%= @post.title %></h1>
      <%= @post.body %>
    </article>
  ERB
end
```

### Render an HTML list from an array

[JSX Lists][jsx lists] use JavaScript's `map` function. Rack::Component does
likewise, only you need to call `join` on the array:

```ruby
require 'rack/component'
class PostsList < Rack::Component
  render do
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
          <a href="/posts/#{post[:id]}">
            #{post[:name]}
          </a>
        </li>
      HTML
    }.join # unlike JSX, you need to call `join` on your array
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
  def render
    Post.magically_filter_via_params(env).to_json
  end
end
```

### Mount a Rack::Component as a Rack app

Because Rack::Components have the same signature as Rack app, you can mount them
anywhere you can mount a Rack app. It's up to you to return a valid rack tuple,
though.

```ruby
# config.ru
require 'rack/component'

class Posts < Rack::Component
  def render
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

### Define `#render` at the instance level instead of via `render do`

The class-level `render` macro exists to make using templates easy, and to lean
on Ruby's keyword arguments as a limited imitation of React's `defaultProps` and
`PropTypes`. But you can define render at the instance level instead.

```ruby
# these two components render identical output

class MacroComponent < Rack::Component
  render do |name:, dept: 'Engineering'|
    "#{name} - #{dept}"
  end
end

class ExplicitComponent < Rack::Component
  def initialize(name:, dept: 'Engineering')
    @name = name
    @dept = dept
    # calling `super` will populate the instance-level `env` hash, making
    # `env` available outside this method. But it's fine to skip it.
    super
  end

  def render
    "#{@name} - #{@dept}"
  end
end
```

## API Reference

The full API reference is available here:

https://www.rubydoc.info/gems/rack-component

## Performance

Run `ruby spec/benchmarks.rb` to see what to expect in your environment. These
results are from a 2015 iMac:

```
$ ruby spec/benchmarks.rb
Warming up --------------------------------------
          stdlib ERB     2.682k i/100ms
            Tilt ERB    15.958k i/100ms
         Bare lambda    77.124k i/100ms
     RC [def render]    64.905k i/100ms
      RC [render do]    57.725k i/100ms
    RC [render erb:]    15.595k i/100ms
Calculating -------------------------------------
          stdlib ERB     27.423k (± 1.8%) i/s -    139.464k in   5.087391s
            Tilt ERB    169.351k (± 2.2%) i/s -    861.732k in   5.090920s
         Bare lambda    929.473k (± 3.0%) i/s -      4.705M in   5.065991s
     RC [def render]    775.176k (± 1.1%) i/s -      3.894M in   5.024347s
      RC [render do]    686.653k (± 2.3%) i/s -      3.464M in   5.046728s
    RC [render erb:]    165.113k (± 1.7%) i/s -    826.535k in   5.007444s
```

Every component in the benchmark is configured to escape HTML when rendering.
When rendering via a block, Rack::Component is about 25x faster than ERB and 4x
faster than Tilt. When rendering a template via Tilt, it (unsurprisingly)
performs roughly at tilt-speed.

## Compatibility

When not rendering Tilt templates, Rack::Component has zero dependencies,
and will work in any Rack app. It should even work _outside_ a Rack app, because
it's not actually dependent on Rack. I packaged it under the Rack namespace
because it follows the Rack `call` specification, and because that's where I
use and test it.

When using Tilt templates, you will need `tilt` and a templating gem in your
`Gemfile`:

```ruby
gem 'tilt'
gem 'erubi' # or gem 'haml', etc
gem 'rack-component'
```

## Anybody using this in production?

Aye:

* [future.com](https://www.future.com/)
* [Seattle & King County Homelessness Response System](https://hrs.kc.future.com/)

## Ruby reference

Where React uses [JSX] to make components more ergonomic, Rack::Component leans
heavily on some features built into the Ruby language, specifically:

* [Heredocs]
* [String Interpolation]
* [Calling methods with a block][ruby blocks]

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
[tilt]: https://github.com/rtomayko/tilt
