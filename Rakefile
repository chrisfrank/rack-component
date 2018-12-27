require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :cop do
  sh 'bundle exec rubocop lib'
end

task :reek do
  sh 'bundle exec reek lib'
end

task :doc do
  sh 'bundle exec yard doc'
end

task :commit do
  sh 'bundle exec rake'
  sh 'git add -A && git commit --verbose'
end

task default: %i[cop reek spec doc]
