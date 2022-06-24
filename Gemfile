source "https://rubygems.org"

gem 'active-triples', git: 'https://github.com/samvera-labs/ActiveTriples.git', branch: 'merge-gitlab-upstream'
gem 'ldp', git: 'https://github.com/samvera/ldp.git', branch: 'allow-ruby-3.0'

# Bundler will rely on active-fedora.gemspec for dependency information.
gemspec path: File.expand_path('..', __FILE__)

gem 'byebug' unless ENV['TRAVIS']
gem 'pry-byebug' unless ENV['CI']

gem 'activemodel', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']

group :test do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'rspec_junit_formatter'
end

gem 'jruby-openssl', platform: :jruby
