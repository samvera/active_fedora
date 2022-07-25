source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)

gem 'byebug' unless ENV['TRAVIS']
gem 'pry-byebug' unless ENV['CI']

if ENV['RAILS_VERSION']
  gem 'activemodel', ENV['RAILS_VERSION']
  gem 'rails', ENV['RAILS_VERSION']
else
  gem 'activemodel', '~> 6.0.4', '< 7'
  gem 'rails', '~> 6.0.4', '< 7'
end

group :test do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'rspec_junit_formatter'
end

gem 'jruby-openssl', platform: :jruby
