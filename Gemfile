source "http://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec

group :development, :test do
  gem 'simplecov', :platforms => [:mri_19]#, :mri_20]
  gem 'simplecov-rcov', :platforms => [:mri_19]#, :mri_20]
end

gem 'jruby-openssl', :platform=> :jruby

gem 'rdf', github: 'ruby-rdf/rdf', ref: '3f131f8' # Keep until rdf 1.0.8 is released
