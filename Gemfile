source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)

gem 'activemodel', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']
gem 'jruby-openssl', platform: :jruby
gem 'pry-byebug' unless ENV['CI']

group :test do
  gem 'coveralls', require: false
  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
end
