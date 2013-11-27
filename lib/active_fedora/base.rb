SOLR_DOCUMENT_ID = "id" unless (defined?(SOLR_DOCUMENT_ID) && !SOLR_DOCUMENT_ID.nil?)
ENABLE_SOLR_UPDATES = true unless defined?(ENABLE_SOLR_UPDATES)
require "digest"
require 'active_support/descendants_tracker'

module ActiveFedora
  
  # This class ties together many of the lower-level modules, and
  # implements something akin to an ActiveRecord-alike interface to
  # fedora. If you want to represent a fedora object in the ruby
  # space, this is the class you want to extend.
  #
  # =The Basics
  #   class Oralhistory < ActiveFedora::Base
  #     has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
  #       m.field "narrator",  :string
  #       m.field "narrator",  :text
  #     end
  #   end
  #
  # The above example creates a Fedora object with a metadata datastream named "properties", which is composed of a 
  # narrator and bio field.
  #
  # Datastreams defined with +has_metadata+ are accessed via the +datastreams+ member hash.
  #
  class Base
    include SemanticNode
    extend Deprecation

    #return the internal fedora URI
    def internal_uri
      self.class.internal_uri(pid)
    end

    def self.internal_uri(pid)
      "info:fedora/#{pid}"
    end

    # @param [String,Array] uris a single uri (as a string) or a list of uris to convert to pids
    # @returns [String] the pid component of the URI
    def self.pids_from_uris(uris) 
      Deprecation.warn(Base, "pids_from_uris has been deprecated and will be removed in active-fedora 8.0.0", caller)
      if uris.kind_of? String
        pid_from_uri(uris)
      else
        Array(uris).map {|uri| pid_from_uri(uri)}
      end
    end

    # Returns a suitable uri object for :has_model
    # Should reverse Model#from_class_uri
    def self.to_class_uri(attrs = {})
      if self.respond_to? :pid_suffix
        pid_suffix = self.pid_suffix
      else
        pid_suffix = attrs.fetch(:pid_suffix, ContentModel::CMODEL_PID_SUFFIX)
      end
      if self.respond_to? :pid_namespace
        namespace = self.pid_namespace
      else
        namespace = attrs.fetch(:namespace, ContentModel::CMODEL_NAMESPACE)
      end
      "info:fedora/#{namespace}:#{ContentModel.sanitized_class_name(self)}#{pid_suffix}" 
    end
  end

  Base.class_eval do
    include Sharding
    include ActiveFedora::Persistence
    extend ActiveSupport::DescendantsTracker
    include Loggable
    include Indexing
    include ActiveModel::Conversion
    include Validations
    include Callbacks
    include Attributes
    include Datastreams
    extend ActiveModel::Naming
    extend Querying
    include Associations
    include AutosaveAssociation
    include NestedAttributes
    include Reflection
    include ActiveModel::Dirty
    include Core
    include FedoraAttributes
  end

end
