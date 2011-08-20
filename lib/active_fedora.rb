require 'rubygems'
require "bundler/setup"

Bundler.require(:default)
gem 'solr-ruby'
require "loggable"

$: << 'lib'

require 'active_support'
require 'active_model'

require 'active_fedora/solr_service.rb'
require "solrizer"

require 'ruby-fedora'
# require 'active_fedora/fedora_object.rb'
# require 'active_fedora/version.rb'
# 
# require 'active_fedora/railtie' if defined?(Rails) && Rails.version >= "3.0"

SOLR_DOCUMENT_ID = ActiveFedora::SolrService.id_field unless defined?(SOLR_DOCUMENT_ID)
ENABLE_SOLR_UPDATES = true unless defined?(ENABLE_SOLR_UPDATES)

module ActiveFedora #:nodoc:
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :Associations
    autoload :AttributeMethods
    autoload :Base
    autoload :ContentModel
    autoload :Reflection
    autoload :Relationship
    autoload :Datastream
    autoload :Delegating
    autoload :Model
    autoload :MetadataDatastream
    autoload :MetadataDatastreamHelper
    autoload :NokogiriDatastream
    autoload :Property
    autoload :QualifiedDublinCoreDatastream
    autoload :RelsExtDatastream
    autoload :SemanticNode
    autoload :NestedAttributes

  end
  
  
  include Loggable
  
  class << self
    attr_accessor :solr_config, :fedora_config, :config_env, :config_path
  end
  
  # The configuration hash that gets used by RSolr.connect
  @solr_config ||= {}
  @fedora_config ||= {}

  # Initializes ActiveFedora's connection to Fedora and Solr based on the info in fedora.yml
  # If Rails.env is set, it will use that environment.  Defaults to "development".
  # @param [String] config_path (optional) the path to fedora.yml
  #   If config_path is not provided and Rails.root is set, it will look in RAILS_ENV/config/fedora.yml.  Otherwise, it will look in your config/fedora.yml.  Failing that, it will use localhost urls.
  def self.init( config_path=nil )
    logger.level = Logger::ERROR
    @config_env = environment
    @config_path = get_config_path(config_path)
    
    logger.info("FEDORA: loading ActiveFedora config from #{File.expand_path(@config_path)}")
    fedora_config = YAML::load(File.open(@config_path))
    raise "The #{@config_env.to_s} environment settings were not found in the fedora.yml config.  If you already have a fedora.yml file defined, make sure it defines settings for the #{@config_env} environment" unless fedora_config[@config_env]
    
    ActiveFedora.solr_config[:url] = fedora_config[@config_env]['solr']['url']
    
    # Register Solr
    logger.info("FEDORA: initializing ActiveFedora::SolrService with solr_config: #{ActiveFedora.solr_config.inspect}")
    
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
    logger.info("FEDORA: initialized Solr with ActiveFedora.solr_config: #{ActiveFedora::SolrService.instance.inspect}")
        
    ActiveFedora.fedora_config[:url] = fedora_config[@config_env]['fedora']['url']
    logger.info("FEDORA: initializing Fedora with fedora_config: #{ActiveFedora.fedora_config.inspect}")
    
    Fedora::Repository.register(ActiveFedora.fedora_config[:url])
    logger.info("FEDORA: initialized Fedora as: #{Fedora::Repository.instance.inspect}")    
    
    # Retrieve the valid path for the predicate mappings config file
    @predicate_config_path = build_predicate_config_path(File.dirname(@config_path))

  end
  
  # Determine what environment we're running in. Order of preference is:
  # 1. Rails.env
  # 2. ENV['environment']
  # 3. ENV['RAILS_ENV']
  # 4. raises an exception if none of these is set
  # @return [String]
  # @example 
  #  Rails.env => "test"
  #  ActiveFedora.init
  #  ActiveFedora.environment => "test"
  def self.environment
    if defined?(Rails.env) and !Rails.env.nil?
      return Rails.env.to_s
    elsif defined?(ENV['environment']) and !(ENV['environment'].nil?)
      return ENV['environment']
    elsif defined?(ENV['RAILS_ENV']) and !(ENV['RAILS_ENV'].nil?)
      logger.warn("You're depending on RAILS_ENV for setting your environment. This is deprecated in Rails3. Please use ENV['environment'] for non-rails environment setting: 'rake foo:bar environment=test'")
      ENV['environment'] = ENV['RAILS_ENV']
      return ENV['environment']
    else
      raise "Can't determine what environment to run in!"
    end
  end
  
  # Determine the config file to use. Order of preference is:
  # 1. Look in Rails.root/config/fedora.yml
  # 2. Look in the current working directory config/fedora.yml
  # 3. Load the default config that ships with this gem
  # @return [String]
  def self.get_config_path(config_path=nil)
    if config_path
      raise ActiveFedoraConfigurationException unless File.file? config_path
      return config_path
    end
    
    if defined?(Rails.root)
      config = "#{Rails.root}/config/fedora.yml"
      return config if File.file? config
    end
    
    if File.file? "#{Dir.getwd}/config/fedora.yml"  
      return "#{Dir.getwd}/config/fedora.yml"
    end
    
    # Last choice, check for the default config file
    config = File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "fedora.yml"))
    logger.warn "Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml as an argument to ActiveFedora.init or set Rails.root and put fedora.yml into \#{Rails.root}/config."
    return config if File.file? config 
    raise ActiveFedoraConfigurationException "Couldn't load config file!"
  end
  
  def self.solr
    ActiveFedora::SolrService.instance
  end
  
  def self.fedora
    Fedora::Repository.instance
  end

  def self.predicate_config
    @predicate_config_path ||= build_predicate_config_path
  end

  def self.version
    ActiveFedora::VERSION
  end

  protected

  def self.build_predicate_config_path(config_path=nil)
    pred_config_paths = [File.expand_path(File.join(File.dirname(__FILE__),"..","config"))]
    pred_config_paths.unshift config_path if config_path
    pred_config_paths.each do |path|
      testfile = File.join(path,"predicate_mappings.yml")
      if File.exist?(testfile) && valid_predicate_mapping?(testfile)
        return testfile
      end
    end
    raise PredicateMappingsNotFoundError #"Could not find predicate_mappings.yml in these locations: #{pred_config_paths.join("; ")}." unless @predicate_config_path
  end

  def self.valid_predicate_mapping?(testfile)
    mapping = YAML::load(File.open(testfile))
    return false unless mapping.has_key?(:default_namespace) && mapping[:default_namespace].is_a?(String)
    return false unless mapping.has_key?(:predicate_mapping) && mapping[:predicate_mapping].is_a?(Hash)
    true
  end
    

end

module ActiveFedora
  class ServerError < Fedora::ServerError; end # :nodoc:
  class ObjectNotFoundError < RuntimeError; end # :nodoc:
  class PredicateMappingsNotFoundError < RuntimeError; end # :nodoc:
  class UnknownAttributeError < NoMethodError; end; # :nodoc:
  class ActiveFedoraConfigurationException < Exception; end # :nodoc:

end

