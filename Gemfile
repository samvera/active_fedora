# frozen_string_literal: true

source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.
gemspec

gem 'active-triples', git: 'https://github.com/samvera-labs/ActiveTriples', branch: 'merge-gitlab-upstream'
gem 'ldp', git: 'https://github.com/samvera/ldp', branch: 'allow-ruby-3.0-fcrepo4'

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
