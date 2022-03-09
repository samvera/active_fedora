source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec path: File.expand_path('..', __FILE__)

# This is for the initial, draft PR
gem 'ldp', git: 'https://github.com/samvera/ldp.git', branch: 'issues-131-jrgriffiniii-ruby3.0'

gem 'jruby-openssl', platform: :jruby

group :development, :test do
  gem 'coveralls', '~> 0.8'
  gem 'pry-byebug' unless ENV['CI']
  gem 'rspec_junit_formatter'
  gem 'simplecov', '~> 0.16'
end

if ENV['RAILS_VERSION']
  gem 'activemodel', ENV['RAILS_VERSION']

  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
    ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
else
  gem 'rails', '~> 6.0'
end

