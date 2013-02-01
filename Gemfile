source "http://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec
gem 'rubydora', github: 'cbeer/rubydora', ref: '190af2c'
group :development, :test do
  gem 'simplecov', :platform => :mri_19
  gem 'simplecov-rcov', :platform => :mri_19
end

gem 'jruby-openssl', :platform=> :jruby
