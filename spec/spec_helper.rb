ENV["RAILS_ENV"] ||= 'test'
require 'active-fedora'
require 'spec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
$VERBOSE=nil

# This loads the Fedora and Solr config info from /config/fedora.yml
# You can load it from a different location by passing a file path as an argument.
ActiveFedora.init(File.join(File.dirname(__FILE__), "..", "config", "fedora.yml"))

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

def fixture(file)
  File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
end
