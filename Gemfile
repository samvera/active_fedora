source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)


gem 'active-triples', github: 'no-reply/ActiveTriples', ref: '4bec618710f7c87369e4e0960742d3943dec0fab'
gem 'ldp', github: 'cbeer/ldp', ref: '4877dc2'
gem 'byebug' unless ENV['TRAVIS']

group :test do
  gem 'simplecov', require: false
end

gem 'jruby-openssl', platform: :jruby
