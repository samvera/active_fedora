source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)

gem 'byebug' unless ENV['TRAVIS']

group :test do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'actionpack'
end

gem 'jruby-openssl', platform: :jruby
