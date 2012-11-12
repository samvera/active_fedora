# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_fedora/version"

Gem::Specification.new do |s|
  s.name        = "active-fedora"
  s.version     = ActiveFedora::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Zumwalt", "McClain Looney", "Justin Coyne"]
  s.email       = ["matt.zumwalt@yourmediashelf.com"]
  s.homepage    = %q{https://github.com/projecthydra/active_fedora}
  s.summary     = %q{A convenience libary for manipulating documents in the Fedora Repository.}
  s.description = %q{ActiveFedora provides for creating and managing objects in the Fedora Repository Architecture.}

  s.rubyforge_project = "rubyfedora"
  s.required_ruby_version     = '>= 1.9.3'

  s.add_dependency('rsolr')
  s.add_dependency('om', '~> 1.8.0.rc1')
  s.add_dependency('solrizer', '~>2.0.0.rc6')
  s.add_dependency("activeresource", '>= 3.0.0')
  s.add_dependency("activesupport", '>= 3.0.0')
  s.add_dependency("builder", '~> 3.0.0')
  s.add_dependency("mediashelf-loggable")
  s.add_dependency("rubydora", '~>0.5.13')
  s.add_dependency("rdf")
  s.add_dependency("rdf-rdfxml", '~>0.3.8')
  s.add_dependency("deprecation")
  s.add_development_dependency("yard")
  s.add_development_dependency("RedCloth") # for RDoc formatting
  s.add_development_dependency("rake")
  s.add_development_dependency("jettywrapper", ">=1.2.0")
  s.add_development_dependency("rspec", ">= 2.9.0")
  s.add_development_dependency("equivalent-xml")
  s.add_development_dependency("mocha", "0.10.5")
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [
    "LICENSE",
    "README.textile"
  ]
  s.require_paths = ["lib"]

end

