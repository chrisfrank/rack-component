# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 - Unreleased
### Fixed
- The `env` argument of the `render` block is now optional, as per standard Ruby
  block behavior.
  ```ruby
  class WorksInThisVersion < Rack::Component
    render do
      'This component raised an ArgumentError in old versions but works now.'
    end
  end

  class StillWorks < Rack::Component
    render do |env|
      'This style still works. Using |keyword:, arguments:| in env is nice.'
    end
  end
  ```

### Added
- A changelog
- Templating via [tilt](https://github.com/rtomayko/tilt), with support for
  escaping HTML by default

### Removed
- Calling `Component.memoized(env)` is no longer supported. Use Sam Saffron's
  [lru_redux](https://github.com/SamSaffron/lru_redux) as an almost drop-in
  replacement, like this:

    ```ruby
    require 'rack/component'
    require 'lru_redux'
    class MyComponent < Rack::Component
      Cache = LruRedux::ThreadSafeCache.new(100)

      render do |env|
        Cache.getset(env) { 'this block will render after checking the cache' }
      end
    end
    ```

## 0.4.2 - 2019-01-04
### Added
- `#h` method for escaping HTML inside interpolated strings

## 0.4.1 - 2019-01-02
- First public, documented release
