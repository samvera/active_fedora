source "http://rubygems.org"

# Bundler will rely on active-fedora.gemspec for dependency information.

gemspec

#gem 'solrizer', github: 'projecthydra/solrizer', branch: 'solrizer-3'
gem 'solrizer', path: '../solrizer'
group :development, :test do
  gem 'simplecov', :platform => :mri_19
  gem 'simplecov-rcov', :platform => :mri_19
end

gem 'jruby-openssl', :platform=> :jruby
