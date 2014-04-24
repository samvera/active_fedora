source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec

gem "fedora_lens", github: 'projecthydra-labs/fedora_lens'
gem "ldp", github: 'cbeer/ldp'
gem 'byebug' unless ENV['TRAVIS']

group :test do
  gem 'simplecov', require: false
end

gem 'jruby-openssl', :platform=> :jruby
