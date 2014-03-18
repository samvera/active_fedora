require "loggable"
require 'active_support'
require "solrizer"
require 'active_fedora/file_configurator'
require 'active_fedora/rubydora_connection'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object'
require 'active_support/core_ext/hash/indifferent_access'
require "active_support/core_ext/hash/except"
require 'rdf'

SOLR_DOCUMENT_ID = Solrizer.default_field_mapper.id_field unless defined?(SOLR_DOCUMENT_ID)
ENABLE_SOLR_UPDATES = true unless defined?(ENABLE_SOLR_UPDATES)

module ActiveFedora #:nodoc:
  extend ActiveSupport::Autoload

  class ObjectNotFoundError < RuntimeError; end # :nodoc:
  class PredicateMappingsNotFoundError < RuntimeError; end # :nodoc:
  class UnknownAttributeError < NoMethodError; end; # :nodoc:
  class ConfigurationError < RuntimeError; end # :nodoc:
  class AssociationTypeMismatch < RuntimeError; end # :nodoc:
  class UnregisteredPredicateError < RuntimeError; end # :nodoc:
  class RecordNotSaved < RuntimeError; end # :nodoc:
  class IllegalOperation < RuntimeError; end # :nodoc:


  eager_autoload do
    autoload :AssociationRelation
    autoload :Associations
    autoload :Attributes
    autoload :Auditable
    autoload :AutosaveAssociation
    autoload :Base
    autoload :ContentModel
    autoload :Callbacks
    autoload :Config
    autoload :Core
    autoload :Datastream
    autoload :DatastreamAttribute
    autoload :DatastreamHash
    autoload :Datastreams
    autoload :DigitalObject
    autoload :FedoraAttributes
    autoload :FileConfigurator
    autoload :Indexing
    autoload :Model
    autoload :NestedAttributes
    autoload :NomDatastream
    autoload :NullRelation
    autoload :OmDatastream
    autoload :Property
    autoload :Persistence
    autoload :QualifiedDublinCoreDatastream
    autoload :Querying
    autoload :Rdf
    autoload_under 'rdf' do
      autoload :RDFDatastream
      autoload :RdfxmlRDFDatastream
      autoload :NtriplesRDFDatastream
    end
    autoload :Reflection
    autoload :Relation
    autoload :ReloadOnSave

    autoload_under 'relation' do
      autoload :Calculations
      autoload :Delegation
      autoload :SpawnMethods
      autoload :QueryMethods
      autoload :FinderMethods
    end

    autoload :RelationshipGraph
    autoload :RelsExtDatastream
    autoload :Scoping
    autoload :SemanticNode
    autoload :ServiceDefinitions
    autoload :Serialization
    autoload :Sharding
    autoload :SimpleDatastream
    autoload :SolrDigitalObject
    autoload :SolrService
    autoload :UnsavedDigitalObject
    autoload :FixtureLoader
    autoload :FixtureExporter
    autoload :DatastreamCollections
    autoload :Predicates
    autoload :Validations
    autoload :SolrInstanceLoader
  end

  module Scoping
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Default
      autoload :Named
    end
  end


  
  include Loggable
  
  class << self
    attr_reader :fedora_config, :solr_config, :config_options
    attr_accessor :configurator
  end
  self.configurator ||= ActiveFedora::FileConfigurator.new
  
  def self.fedora_config
    @fedora_config ||= Config.new(configurator.fedora_config)
  end
  def self.solr_config;    self.configurator.solr_config;    end
  def self.config_options; self.configurator.config_options; end
  def self.config_loaded?; self.configurator.config_loaded?; end
  
  def self.init( options={} )
    # Make config_options into a Hash if nil is passed in as the value
    options = {} if options.nil?
    # For backwards compatibility, handle cases where config_path (a String) is passed in as the argument rather than a config_options hash
    # In all other cases, set config_path to config_options[:config_path], which is ok if it's nil
    if options.is_a? String
      raise ArgumentError, "Calling ActiveFedora.init with a path as an argument has been removed.  Use ActiveFedora.init(:fedora_config_path=>#{options})"
    end
    @fedora_config = nil
    SolrService.reset!
    Predicates.predicate_config = nil
    self.configurator.init(options)
  end

  def self.config
    self.fedora_config
  end

  # Determine what environment we're running in. Order of preference is:
  # 1. config_options[:environment]
  # 2. Rails.env
  # 3. ENV['environment']
  # 4. ENV['RAILS_ENV']
  # 5. development
  # @return [String]
  # @example 
  #  ActiveFedora.init(:environment=>"test")
  #  ActiveFedora.environment => "test"
  def self.environment
    if config_options.fetch(:environment,nil)
      return config_options[:environment]
    elsif defined?(Rails.env) and !Rails.env.nil?
      return Rails.env.to_s
    elsif defined?(ENV['environment']) and !(ENV['environment'].nil?)
      return ENV['environment']
    elsif defined?(ENV['RAILS_ENV']) and !(ENV['RAILS_ENV'].nil?)
      raise RuntimeError, "You're depending on RAILS_ENV for setting your environment. Please use ENV['environment'] for non-rails environment setting: 'rake foo:bar environment=test'"
    else
      ENV['environment'] = 'development' 
    end
  end
  
  def self.solr
    ActiveFedora::SolrService.instance
  end
  
  def self.predicate_config
    configurator.predicate_config
  end
  
  def self.root
    File.expand_path('../..', __FILE__)
  end
  
  def self.version
    ActiveFedora::VERSION
  end
  
  # Convenience method for getting class constant based on a string
  # @example
  #   ActiveFedora.class_from_string("Om")
  #   => Om
  #   ActiveFedora.class_from_string("ActiveFedora::RdfNode::TermProxy")
  #   => ActiveFedora::RdfNode::TermProxy
  # @example Search within ActiveFedora::RdfNode for a class called "TermProxy"
  #   ActiveFedora.class_from_string("TermProxy", ActiveFedora::RdfNode)
  #   => ActiveFedora::RdfNode::TermProxy  
  def self.class_from_string(class_name, container_class=Kernel)
    container_class = container_class.name if container_class.is_a? Module
    container_parts = container_class.split('::')
    (container_parts + class_name.split('::')).flatten.inject(Kernel) do |mod, class_name|
      if mod == Kernel
        Object.const_get(class_name)
      elsif mod.const_defined? class_name.to_sym
        mod.const_get(class_name)
      else
        container_parts.pop
        class_from_string(class_name, container_parts.join('::'))
      end
    end
  end

end


I18n.load_path << File.dirname(__FILE__) + '/active_fedora/locale/en.yml'

require 'active_fedora/railtie' if defined?(Rails)
