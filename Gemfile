# frozen_string_literal: true

source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.
gemspec

gem 'active-triples', path: '/Users/jrg5/src/github.com/samvera-labs/ActiveTriples'
gem 'ldp', path: '/Users/jrg5/src/github.com/samvera/workspace6/ldp'

gem 'jruby-openssl', platform: :jruby
gem 'pry-byebug' unless ENV['CI']

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'activemodel'
    gem 'rails', github: 'rails/rails'
  else
    gem 'activemodel', ENV['RAILS_VERSION']
    gem 'rails', ENV['RAILS_VERSION']
  end
end

group :test do
  gem 'coveralls', require: false
  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
end
