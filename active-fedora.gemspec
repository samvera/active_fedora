# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_fedora/version"

Gem::Specification.new do |s|
  s.name        = "active-fedora"
  s.version     = ActiveFedora::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Zumwalt", "McClain Looney", "Justin Coyne"]
  s.email       = ["samvera-tech@googlegroups.com"]
  s.homepage    = 'https://github.com/samvera/active_fedora'
  s.summary     = 'A convenience libary for manipulating documents in the Fedora Repository.'
  s.description = 'ActiveFedora provides for creating and managing objects in the Fedora Repository Architecture.'
  s.license = "Apache-2.0"
  s.metadata = { "rubygems_mfa_required" => "true" }
  s.required_ruby_version = '>= 2.6'

  s.add_dependency "activemodel", '>= 6.1'
  s.add_dependency "activesupport", '>= 6.1'
  s.add_dependency "active-triples", '>= 0.11.0', '< 2.0.0'
  s.add_dependency "deprecation"
  s.add_dependency 'faraday', '>= 1.0'
  s.add_dependency 'faraday-encoding', '>= 0.0.5'
  s.add_dependency "ldp", '>= 0.7.0', '< 2'
  s.add_dependency "mutex_m"
  s.add_dependency 'rsolr', '>= 1.1.2', '< 3'
  s.add_dependency "ruby-progressbar", '~> 1.0'

  s.add_development_dependency "bixby"
  s.add_development_dependency "equivalent-xml"
  s.add_development_dependency 'fcrepo_wrapper', '~> 0.2'
  s.add_development_dependency "github_changelog_generator"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "rails"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "simplecov", '~> 0.8'
  s.add_development_dependency "solr_wrapper", "~> 4.0"
  s.add_development_dependency "yard"

  s.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR).select { |f| File.dirname(f) !~ %r{\A"?spec\/?} }
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.require_paths = ["lib"]
end
