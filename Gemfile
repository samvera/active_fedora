source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)

gem 'byebug' unless ENV['TRAVIS']
gem 'pry-byebug' unless ENV['CI']
# From https://github.com/ActiveTriples/ActiveTriples/pull/150
gem 'active-triples', github: 'ActiveTriples/ActiveTriples', ref: 'b4a0087'


group :test do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
end

gem 'jruby-openssl', platform: :jruby
