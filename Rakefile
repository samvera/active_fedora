require 'rake/clean'
require 'lib/active_fedora'#to get VERSION
require 'rubygems'
load 'tasks/rspec.rake'
$: << 'lib'


begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "active-fedora"
    gem.summary = %Q{A convenience libary for manipulating MODS (Metadata Object Description Schema) documents.}
    gem.description = %Q{ActiveFedora provides for creating and managing objects in the Fedora Repository Architecture.}
    gem.email = "matt.zumwalt@yourmediashelf.com"
    gem.homepage = "http://yourmediashelf.com/activefedora"
    gem.authors = ["Matt Zumwalt", "McClain Looney"]
    gem.add_dependency('solr-ruby', '>= 0.0.6')
    gem.add_dependency('xml-simple', '>= 1.0.12')
    gem.add_dependency('mime-types', '>= 1.16')
    gem.add_dependency('multipart-post')

    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "mocha", ">= 1.2.9"
    gem.add_development_dependency "ruby-debug"

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

CLEAN.include %w[**/.DS_Store tmp *.log *.orig *.tmp **/*~]

task :default => [:spec]
