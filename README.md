# Rack::Component

Like a React.js component, a `Rack::Component` implements a `render` method that
takes input data and returns what to display.

You can combine Components to build complex features out of simple, easily
testable units.

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

Please see the
[YARD docs on rubydoc.info](https://www.rubydoc.info/gems/rack-component)

## Usage

Subclass `Rack::Component` and `#call` it:

```ruby
require 'rack/component'
class Useless < Rack::Component
end

Useless.call #=> the output Useless.new.render
```

The default implementation of `#render` is to yield the component instance to
whatever block you pass to `Component.call`, like this:

```ruby
Useless.call { |instance| "Hello from #{instance}" }
#=> "Hello from #<Useless:0x00007fcaba87d138>"

Useless.call do |instance|
  Useless.call do |second_instance|
    <<~HTML
      <h1>Hello from #{instance}</h1>
      <p>And also from #{second_instance}"</p>
    HTML
  end
end
# =>
# <h1>Hello from #<Useless:0x00007fcaba87d138></h1>
# <p>And also from #<Useless:0x00007f8482802498></p>
```

### Implement `#render` or add instance methods to make Components do work

Peruse the [specs][specs] for examples of component chains that handle
data fetching, views, and error handling in Sinatra and raw Rack.

Here's a component chain that prints headlines from Daring Fireball’s JSON feed:

```ruby
require 'rack/component'

# Make a network request and return the response
class Fetcher < Rack::Component
  require 'net/http'
  def initialize(uri:)
    @response = Net::HTTP.get(URI(uri))
  end

  def render
    yield @response
  end
end

# Parse items from a JSON Feed document
class JSONFeedParser < Rack::Component
  require 'json'
  def initialize(data)
    @items = JSON.parse(data).fetch('items')
  end

  def render
    yield @items
  end
end

# Render an HTML list of posts
class PostsList < Rack::Component
  def initialize(posts:, style: '')
    @posts = posts
    @style = style
  end

  def render
    <<~HTML
      <ul style="#{@style}">
        #{@posts.map(&ListItem).join}"
      </ul>
    HTML
  end

  ListItem = ->(post) { "<li>#{post['title']}</li>" }
end

# Fetch JSON Feed data from daring fireball, parse it, render a list
Fetcher.call(uri: 'https://daringfireball.net/feeds/json') do |data|
  JSONFeedParser.call(data) do |items|
    PostsList.call(posts: items, style: 'background-color: red')
  end
end
end
#=> A <ul> full of headlines from Daring Fireball

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

[specs]: https://github.com/chrisfrank/rack-component/tree/master/spec
