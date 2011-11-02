ENV["environment"] ||= 'test'
require "bundler/setup"
require 'active-fedora'
require 'spec'
require 'equivalent-xml/rspec_matchers'

require 'support/mock_fedora'


logger.level = Logger::WARN if logger.respond_to? :level ###MediaShelf StubLogger doesn't have a level= method

$:.unshift(File.dirname(__FILE__) + '/../lib')
$VERBOSE=nil

# This loads the Fedora and Solr config info from /config/fedora.yml
# You can load it from a different location by passing a file path as an argument.
ActiveFedora.init(:fedora_config_path=>File.join(File.dirname(__FILE__), "..", "config", "fedora.yml"))

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

def fixture(file)
  File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
end
