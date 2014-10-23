source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)


gem 'active-triples', github: 'no-reply/ActiveTriples', ref: '4bec618710f7c87369e4e0960742d3943dec0fab'
gem 'ldp', github: 'cbeer/ldp', ref: 'd60389000503b44b98a8ce8b6dccc5ce0f4a02f4'
gem 'byebug' unless ENV['TRAVIS']

group :test do
  gem 'simplecov', require: false
end

gem 'jruby-openssl', platform: :jruby
