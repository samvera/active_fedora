require 'rake/clean'
require 'bundler'

Bundler::GemHelper.install_tasks

# load rake tasks defined in lib/tasks that are not loaded in lib/active_fedora.rb
load "lib/tasks/active_fedora_dev.rake"

CLEAN.include %w(**/.DS_Store tmp *.log *.orig *.tmp **/*~)

desc 'setup jetty and run tests'
task ci: ['active_fedora:ci']
desc 'run tests'
task spec: ['active_fedora:rubocop', 'active_fedora:rspec']
task rcov: ['active_fedora:rcov']

task default: [:ci]
