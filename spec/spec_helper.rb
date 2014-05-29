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

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f }
require 'samples/samples'


#Ldp.logger.level = Logger::DEBUG
logger.level = Logger::WARN if logger.respond_to? :level ###MediaShelf StubLogger doesn't have a level= method
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
  # Stub out test stuff.
  config.before(:each) do
    begin
      FedoraLens.connection.delete("test")
    rescue StandardError
    end
    FedoraLens.connection.put("test","")
    restore_spec_configuration if ActiveFedora::SolrService.instance.nil? || ActiveFedora::SolrService.instance.conn.nil?
    ActiveFedora::SolrService.instance.conn.delete_by_query('*:*')
    ActiveFedora::SolrService.commit
    host = FedoraLens.host+"/test"
    connection = Ldp::Client.new(host)
    FedoraLens.stub(:connection).and_return(connection)
    FedoraLens.stub(:host).and_return(host)
  end
end

def fixture(file)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', file), 'rb')
end

def solr_uri(uri)
  uri.gsub(/(:)/, "\\:").gsub(/(\/)/,"\\/")
end
