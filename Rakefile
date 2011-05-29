require 'rake/clean'
require 'rubygems'
require 'bundler'

$: << 'lib'

Bundler::GemHelper.install_tasks

# load rake tasks defined in lib/tasks
Dir["lib/tasks/**/*.rake"].each { |ext| load ext } if defined?(Rake)

CLEAN.include %w[**/.DS_Store tmp *.log *.orig *.tmp **/*~]

task :default => [:spec]
