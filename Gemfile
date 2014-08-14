source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)


gem "ldp", github: 'cbeer/ldp'
gem 'active-triples', github: 'jcoyne/ActiveTriples', branch: 'array_accessors'
gem 'byebug' unless ENV['TRAVIS']

group :test do
  gem 'simplecov', require: false
end

gem 'jruby-openssl', platform: :jruby
