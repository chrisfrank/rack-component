# Rack::Component

Respond to HTTP requests by composing `Rack::Component`s.

Like a React.js component, a `Rack::Component` implements a render() method that takes input data and returns what to display.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-component', require: 'rack/component'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-component

## Usage

You could build an entire Rack app out of `Rack::Component`s, but I mostly use it inside Sinatra and Roda apps, as an alternative to Controllers and Views.

### With Sinatra
```ruby




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
