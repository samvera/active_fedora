# frozen_string_literal: true

source "https://rubygems.org"

gem 'active-triples', git: 'https://github.com/samvera-labs/ActiveTriples.git', branch: 'merge-gitlab-upstream'
gem 'jruby-openssl', platform: :jruby
gem 'ldp', git: 'https://github.com/samvera/ldp.git', branch: 'allow-ruby-3.0'
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

# Bundler will rely on active-fedora.gemspec for dependency information.
gemspec path: File.expand_path(__dir__)
