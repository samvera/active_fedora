source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)

gem 'byebug' unless ENV['TRAVIS']
gem 'pry-byebug' unless ENV['CI']

if ENV['RAILS_VERSION']
  gem 'activemodel', ENV['RAILS_VERSION']
  gem 'rails', ENV['RAILS_VERSION']
else
  gem 'activemodel', '>= 6.0', '< 8'
  gem 'rails', '>= 6.0', '< 8'
end

group :test do
  gem 'coveralls', require: false
  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
end

gem 'jruby-openssl', platform: :jruby

# rdf-tabular has a dependency on csv but it was removed from the ruby standard library starting in 3.4
gem "csv", "~> 3.0" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
