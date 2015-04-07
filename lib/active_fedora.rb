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
require 'rdf/ldp'

SOLR_DOCUMENT_ID = Solrizer.default_field_mapper.id_field unless defined?(SOLR_DOCUMENT_ID)
ENABLE_SOLR_UPDATES = true unless defined?(ENABLE_SOLR_UPDATES)

# Monkey patching RDF::Literal::DateTime to support fractional seconds.
# See https://github.com/projecthydra/active_fedora/issues/497
module RDF
  class Literal
    class DateTime < Literal
      ALTERNATIVE_FORMAT   = '%Y-%m-%dT%H:%M:%S'.freeze
      DOT                  = '.'.freeze
      Z                    = 'Z'.freeze
      EMPTY                = ''.freeze

      def to_s
        @string ||= begin
          # Show nanoseconds but remove trailing zeros
          nano = @object.strftime('%N').sub(/0+\Z/, EMPTY)
          nano = DOT + nano unless nano.blank?
          @object.strftime(ALTERNATIVE_FORMAT) + nano + Z
        end
      end
    end
  end
end

module ActiveFedora #:nodoc:
  extend ActiveSupport::Autoload

  eager_autoload do
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
    autoload :Config
    autoload :Core
    autoload :Datastream
    autoload :Datastreams
    autoload :DelegatedAttribute
    autoload :Fedora
    autoload :FedoraAttributes
    autoload :File
    autoload :FileConfigurator
    autoload :FilePathBuilder
    autoload :FilesHash
    autoload :FixityService
    autoload :Indexing
    autoload :IndexingService
    autoload :InheritableAccessors
    autoload :LdpCache
    autoload :LdpResource
    autoload :LdpResourceService
    autoload :LoadableFromJson
    autoload :Model
    autoload :NestedAttributes
    autoload :NomDatastream
    autoload :NullRelation
    autoload :OmDatastream
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

    autoload :Scoping
    autoload :Serialization
    autoload :SimpleDatastream
    autoload :SolrInstanceLoader
    autoload :SolrQueryBuilder
    autoload :SolrService
    autoload :SparqlInsert
    autoload :Predicates
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
    def solr_config;    configurator.solr_config;    end
    def config_options; configurator.config_options; end
    def config_loaded?; configurator.config_loaded?; end

    def init( options={} )
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

    def solr
      ActiveFedora::SolrService.instance
    end

    def fedora
      @fedora ||= Fedora.new(fedora_config.credentials)
    end

    def predicate_config
      configurator.predicate_config
    end

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
    def class_from_string(class_name, container_class=Kernel)
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

  self.configurator ||= ActiveFedora::FileConfigurator.new

end


I18n.load_path << ::File.dirname(__FILE__) + '/active_fedora/locale/en.yml'

require 'active_fedora/railtie' if defined?(Rails)
