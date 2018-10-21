require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :cop do
  system 'bundle exec rubocop lib'
end

task :reek do
  system 'bundle exec reek lib'
end

task :doc do
  system 'bundle exec yard doc'
end

task default: %i[cop reek spec doc]
