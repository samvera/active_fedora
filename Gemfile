source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec

#gem "fedora_lens", github: 'curationexperts/fedora_lens'
gem "fedora_lens", path: '../fedora_lens'
gem "ldp", path: '../ldp'
gem 'byebug' unless ENV['TRAVIS']

group :test do
  gem 'simplecov', require: false
end

gem 'jruby-openssl', :platform=> :jruby
