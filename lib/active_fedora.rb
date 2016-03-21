require 'active_support'
require 'active_model'
require 'ldp'
require 'solrizer'
require 'active_fedora/file_configurator'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/except'
require 'active_triples'

# Monkey patching RDF::Literal::DateTime to support fractional seconds.
# See https://github.com/projecthydra/active_fedora/issues/497
# Also monkey patches in a fix for timezones to be stored properly.
module RDF
  class Literal
    class DateTime < Literal
      ALTERNATIVE_FORMAT   = '%Y-%m-%dT%H:%M:%S'.freeze
      DOT                  = '.'.freeze
      EMPTY                = ''.freeze
      TIMEZONE_FORMAT      = '%:z'.freeze

      def to_s
        @string ||= begin
          # Show nanoseconds but remove trailing zeros
          nano = @object.strftime('%N').sub(/0+\Z/, EMPTY)
          nano = DOT + nano unless nano.blank?
          @object.strftime(ALTERNATIVE_FORMAT) + nano + @object.strftime(TIMEZONE_FORMAT)
        end
      end
    end
  end
end

module ActiveFedora #:nodoc:
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :AssociationHash
    autoload :AssociationRelation
    autoload :Associations
    autoload :AttachedFiles
    autoload :AttributeMethods
    autoload :Attributes
    autoload :AutosaveAssociation
    autoload :Base
    autoload :CachingConnection
    autoload :Callbacks
    autoload :ChangeSet
    autoload :Checksum
    autoload :CleanConnection
    autoload :Config
    autoload :Core
    autoload_under 'containers' do
      autoload :Container
      autoload :DirectContainer
      autoload :IndirectContainer
    end
    autoload :Datastream
    autoload :Datastreams
    autoload :DelegatedAttribute
    autoload_under 'attributes' do
      autoload :StreamAttribute
      autoload :ActiveTripleAttribute
      autoload :OmAttribute
      autoload :RdfDatastreamAttribute
    end
    autoload :DefaultModelMapper
    autoload :Fedora
    autoload :FedoraAttributes
    autoload :File
    autoload :FileConfigurator
    autoload :FilePathBuilder
    autoload :FilePersistence
    autoload :FileRelation
    autoload :FilesHash
    autoload :FixityService
    autoload :Identifiable
    autoload :Indexers
    autoload :Indexing
    autoload :IndexingService
    autoload :InheritableAccessors
    autoload :InboundRelationConnection
    autoload :LdpCache
    autoload :LdpResource
    autoload :LdpResourceService
    autoload :LoadableFromJson
    autoload :Model
    autoload :ModelClassifier
    autoload :NestedAttributes
    autoload :NomDatastream
    autoload :NullRelation
    autoload :OmDatastream
    autoload :Pathing
    autoload :Persistence
    autoload :ProfileIndexingService
    autoload :Property
    autoload :QualifiedDublinCoreDatastream
    autoload :Querying
    autoload :QueryResultBuilder
    autoload :RDF
    autoload_under 'rdf' do
      autoload :RDFDatastream
      autoload :RDFXMLDatastream
      autoload :NtriplesRDFDatastream
      autoload :FedoraRdfResource
    end
    autoload :Reflection
    autoload :Relation

    autoload_under 'relation' do
      autoload :Calculations
      autoload :Delegation
      autoload :SpawnMethods
      autoload :QueryMethods
      autoload :FinderMethods
    end

    autoload :Schema
    autoload :Scoping
    autoload :Serialization
    autoload :SimpleDatastream
    autoload :SchemaIndexingStrategy
    autoload :SolrHit
    autoload :SolrInstanceLoader
    autoload :SolrQueryBuilder
    autoload :SolrService
    autoload :SparqlInsert
    autoload :Predicates
    autoload :Type
    autoload :Validations
    autoload :Versionable
    autoload :VersionsGraph
    autoload :WithMetadata
  end

  module AttributeMethods
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Read
      autoload :Write
      autoload :Dirty
    end
  end

  module Attributes
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Serializers
      autoload :PrimaryKey
      autoload :PropertyBuilder
      autoload :NodeConfig
    end
  end

  module Scoping
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Default
      autoload :Named
    end
  end

  class << self
    attr_reader :fedora_config, :solr_config, :config_options
    attr_accessor :configurator

    def fedora_config
      @fedora_config ||= Config.new(configurator.fedora_config)
    end

    delegate :solr_config, to: :configurator

    delegate :config_options, to: :configurator

    delegate :config_loaded?, to: :configurator

    def init(options = {})
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
      configurator.init(options)
    end

    def config
      fedora_config
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
    def environment
      if config_options.fetch(:environment, nil)
        return config_options[:environment]
      elsif defined?(Rails.env) && !Rails.env.nil?
        return Rails.env.to_s
      elsif defined?(ENV['environment']) && !ENV['environment'].nil?
        return ENV['environment']
      elsif defined?(ENV['RAILS_ENV']) && !ENV['RAILS_ENV'].nil?
        raise "You're depending on RAILS_ENV for setting your environment. Please use ENV['environment'] for non-rails environment setting: 'rake foo:bar environment=test'"
      else
        ENV['environment'] = 'development'
      end
    end

    def solr
      ActiveFedora::SolrService.instance
    end

    def fedora
      @fedora ||= Fedora.new(fedora_config.credentials)
    end

    delegate :predicate_config, to: :configurator

    def root
      ::File.expand_path('../..', __FILE__)
    end

    def version
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
    def class_from_string(*args)
      ActiveFedora::ModelClassifier.class_from_string(*args)
    end

    def model_mapper
      ActiveFedora::DefaultModelMapper.new
    end

    def index_field_mapper
      Solrizer.default_field_mapper
    end

    def id_field
      if defined?(SOLR_DOCUMENT_ID) && !SOLR_DOCUMENT_ID.nil?
        SOLR_DOCUMENT_ID
      elsif defined?(Solrizer)
        Solrizer.default_field_mapper.id_field
      else
        'id'.freeze
      end
    end

    def enable_solr_updates?
      if defined?(ENABLE_SOLR_UPDATES)
        ENABLE_SOLR_UPDATES
      else
        true
      end
    end
  end

  self.configurator ||= ActiveFedora::FileConfigurator.new
end

I18n.load_path << ::File.dirname(__FILE__) + '/active_fedora/locale/en.yml'

require 'active_fedora/railtie' if defined?(Rails)
