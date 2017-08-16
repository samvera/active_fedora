source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec

group :development, :test do
  gem 'simplecov', :platforms => [:mri_19]#, :mri_20]
  gem 'simplecov-rcov', :platforms => [:mri_19]#, :mri_20]
end

gem 'jruby-openssl', :platform=> :jruby

gem 'activemodel', '~> 4.2'
gem 'rake', '~> 11.0' # Rspec version 2.99 requires rake < 12
