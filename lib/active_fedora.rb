require 'rubygems'
gem 'solr-ruby'
require "loggable"

$: << 'lib'
require 'logger'
require 'active_fedora/solr_service.rb'
require "solrizer"

require 'ruby-fedora'
require 'active_fedora/base.rb'
require 'active_fedora/content_model.rb'
require 'active_fedora/datastream.rb'
require 'active_fedora/fedora_object.rb'
require 'active_fedora/metadata_datastream_helper.rb'
require 'active_fedora/metadata_datastream.rb'
require 'active_fedora/nokogiri_datastream'
require 'active_fedora/model.rb'
require 'active_fedora/property.rb'
require 'active_fedora/qualified_dublin_core_datastream.rb'
require 'active_fedora/relationship.rb'
require 'active_fedora/rels_ext_datastream.rb'
require 'active_fedora/semantic_node.rb'
require 'active_fedora/version.rb'

SOLR_DOCUMENT_ID = ActiveFedora::SolrService.id_field unless defined?(SOLR_DOCUMENT_ID)
ENABLE_SOLR_UPDATES = true unless defined?(ENABLE_SOLR_UPDATES)

module ActiveFedora #:nodoc:
  
  class << self
    attr_accessor :solr_config, :fedora_config
  end
  
  # The configuration hash that gets used by RSolr.connect
  @solr_config ||= {}
  @fedora_config ||= {}

  # Initializes ActiveFedora's connection to Fedora and Solr based on the info in fedora.yml
  # If RAILS_ENV is set, it will use that environment.  Defaults to "development".
  # @param [String] config_path (optional) the path to fedora.yml
  #   If config_path is not provided and RAILS_ROOT is set, it will look in RAILS_ENV/config/fedora.yml.  Otherwise, it will look in your config/fedora.yml.  Failing that, it will use localhost urls.
  def self.init( config_path=nil )
    
    config_env = defined?(RAILS_ENV) ? RAILS_ENV : "development"
    
    if config_path.nil? 
      if defined?(RAILS_ROOT)
        config_path = "#{RAILS_ROOT}/config/fedora.yml"
      else
        config_path = File.join("config","fedora.yml")
        unless File.exist?(config_path)
          config_path = File.join(File.dirname(__FILE__), "..", "config", "fedora.yml")
          logger.info "Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml as an argument to ActiveFedora.init or set RAILS_ROOT and put fedora.yml into \#{RAILS_ROOT}/config."
        end
      end
    end

    
    logger.info("FEDORA: loading ActiveFedora config from #{File.expand_path(config_path)}")
    
    fedora_config = YAML::load(File.open(config_path))
    raise "The #{config_env} environment settings were not found in the fedora.yml config.  If you already have a fedora.yml file defined, make sure it defines settings for the #{config_env} environment" unless fedora_config[config_env]
    
    ActiveFedora.solr_config[:url] = fedora_config[config_env]['solr']['url']
    
    # Register Solr
    logger.info("FEDORA: initializing ActiveFedora::SolrService with solr_config: #{ActiveFedora.solr_config.inspect}")
    
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
    logger.info("FEDORA: initialized Solr with ActiveFedora.solr_config: #{ActiveFedora::SolrService.instance.inspect}")
        
    ActiveFedora.fedora_config[:url] = fedora_config[config_env]['fedora']['url']
    logger.info("FEDORA: initializing Fedora with fedora_config: #{ActiveFedora.fedora_config.inspect}")
    
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
    logger.info("FEDORA: initialized Fedora as: #{Fedora::Repository.instance.inspect}")    
    
    # Retrieve the valid path for the predicate mappings config file
    pred_config_paths = [File.dirname(config_path),File.join(File.dirname(__FILE__),"..","config")]
    pred_config_paths.each do |path|
      testfile = File.join(path,"predicate_mappings.yml")
      if File.exist?(testfile)
        @predicate_config_path = testfile
        break
      end
    end
    raise "Could not find predicate_mappings.yml in these locations: #{pred_config_paths.join("; ")}." unless @predicate_config_path


  end
  
  def self.solr
    ActiveFedora::SolrService.instance
  end
  
  def self.fedora
    Fedora::Repository.instance
  end

  def self.logger      
    @logger ||= defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER : Logger.new(STDOUT)
  end

  def self.predicate_config
    @predicate_config_path
  end

  def self.version
    ActiveFedora::VERSION
  end
end




# if ![].respond_to?(:count)
#   class Array
#     puts "active_fedora is Adding count method to Array"
#       def count(&action)
#         count = 0
#          self.each { |v| count = count + 1}
#   #      self.each { |v| count = count + 1 if action.call(v) }
#         return count
#       end
#   end
# end

module ActiveFedora
  class ServerError < Fedora::ServerError; end # :nodoc:
  class ObjectNotFoundError < RuntimeError; end # :nodoc:
end

