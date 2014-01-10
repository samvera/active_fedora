source "https://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec

gem 'rubydora', github: 'projecthydra/rubydora', ref: '93b2000'#'~> 1.7.0'
  

group :development, :test do
  gem 'simplecov', :platforms => [:mri_19]#, :mri_20]
  gem 'simplecov-rcov', :platforms => [:mri_19]#, :mri_20]
end

gem 'jruby-openssl', :platform=> :jruby
