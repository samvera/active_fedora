source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)


gem "ldp", github: 'cbeer/ldp'
gem 'byebug' unless ENV['TRAVIS']

group :test do
  gem 'simplecov', require: false
end

gem 'jruby-openssl', :platform=> :jruby
