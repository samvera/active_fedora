ENV["environment"] ||= 'test'
require "bundler/setup"


begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  #It's nbd if we don't have simplecov
  $stderr.puts "Couldn't load simplecov"
end

require 'active-fedora'
require 'rspec'
require 'rspec/its'
require 'equivalent-xml/rspec_matchers'
require 'logger'

ActiveFedora::Base.logger = Logger.new(STDERR);
ActiveFedora::Base.logger.level = Logger::WARN

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f }
require 'samples/samples'

$VERBOSE=nil

# This loads the Fedora and Solr config info from /config/fedora.yml
# You can load it from a different location by passing a file path as an argument.
def restore_spec_configuration
  ActiveFedora.init(:fedora_config_path=>File.join(File.dirname(__FILE__), "..", "config", "fedora.yml"))
end
restore_spec_configuration

# Shut those Rails deprecation warnings up
ActiveSupport::Deprecation.behavior= Proc.new { |message, callstack| }

RSpec.configure do |config|
end

def fixture(file)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', file), 'rb')
end

def solr_uri(uri)
  uri.gsub(/(:)/, "\\:").gsub(/(\/)/,"\\/")
end
