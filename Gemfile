source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec

group :test do
  gem 'simplecov', require: false
end

gem 'jruby-openssl', :platform=> :jruby
gem 'activemodel', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']
gem 'linkeddata', '~> 1.99'
gem 'rake', '< 12'
