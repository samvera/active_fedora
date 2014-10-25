ENV["environment"] ||= 'test'
require "bundler/setup"

if ENV["COVERAGE"]
  require 'simplecov'

  SimpleCov.start do
    add_filter "/spec/"
  end
end

require 'active-fedora'
require 'rspec'
require 'equivalent-xml/rspec_matchers'
require 'logger'
require 'byebug' unless ENV['TRAVIS']

ActiveFedora::Base.logger = Logger.new(STDERR)
ActiveFedora::Base.logger.level = Logger::WARN
# HttpLogger.logger = Logger.new(STDOUT)
# HttpLogger.ignore = [/localhost:8983\/solr/]
# HttpLogger.colorize = false
# HttpLogger.log_headers = true

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
  # Stub out test stuff.
  config.before(:each) do
    cleanout_fedora
    reinitialize_repo
    cleanout_solr
  end
  config.after(:each) do
    # cleanout_fedora
  end
  config.order = :random
end

def fixture(file)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', file), 'rb')
end

def solr_uri(uri)
  uri.gsub(/(:)/, "\\:").gsub(/(\/)/,"\\/")
end

def cleanout_fedora
  tombstone_path = ActiveFedora.fedora.base_path.sub('/', '') + "/fcr:tombstone"
  begin
    ActiveFedora.fedora.connection.delete(ActiveFedora.fedora.base_path.sub('/', ''))
    ActiveFedora.fedora.connection.delete(tombstone_path)
  rescue Ldp::HttpError => exception
    ActiveFedora::Base.logger.debug "#cleanout_fedora in spec_helper.rb raised #{exception}"
  end
end

def cleanout_solr
  restore_spec_configuration if ActiveFedora::SolrService.instance.nil? || ActiveFedora::SolrService.instance.conn.nil?
  ActiveFedora::SolrService.instance.conn.delete_by_query('*:*', params: {'softCommit' => true})
end

def reinitialize_repo
  begin
    ActiveFedora.fedora.connection.put(ActiveFedora.fedora.base_path.sub('/', ''),"")
  rescue Ldp::HttpError
    ActiveFedora::Base.logger.debug "#reinitialize_repo in spec_helper.rb raised #{exception}"
  end
end
