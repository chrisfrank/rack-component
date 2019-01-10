lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/component/version'

Gem::Specification.new do |spec|
  spec.name          = 'rack-component'
  spec.version       = Rack::Component::VERSION
  spec.authors       = ['Chris Frank']
  spec.email         = ['chris.frank@future.com']
  spec.licenses      = ['MIT']

  spec.summary       = 'Compose declarative, component-based responses to HTTP requests'
  spec.homepage      = 'https://www.github.com/chrisfrank/rack-component'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2'

  spec.add_development_dependency 'benchmark-ips', '~> 2.7'
  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'erubi', '~> 1.8'
  spec.add_development_dependency 'haml', '~> 5'
  spec.add_development_dependency 'liquid', '~> 4'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'rack', '~> 2.0.6'
  spec.add_development_dependency 'rack-test', '~> 0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'reek', '~> 5'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.59'
  spec.add_development_dependency 'tilt', '~> 2'
  spec.add_development_dependency 'yard', '~> 0.9'
end
