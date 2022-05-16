source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)

gem 'byebug' unless ENV['TRAVIS']
gem 'pry-byebug' unless ENV['CI']

gem 'activemodel', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']

group :test do
  gem 'coveralls', require: false
  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
end

gem 'jruby-openssl', platform: :jruby
