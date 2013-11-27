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

    delegate :state=,:label=, to: :inner_object

    def mark_for_destruction
      @marked_for_destruction = true
    end

    def marked_for_destruction?
      @marked_for_destruction
    end

    def self.datastream_class_for_name(dsid)
      ds_specs[dsid] ? ds_specs[dsid].fetch(:type, ActiveFedora::Datastream) : ActiveFedora::Datastream
    end

    #return the pid of the Fedora Object
    # if there is no fedora object (loaded from solr) get the instance var
    # TODO make inner_object a proxy that can hold the pid
    def pid
       @inner_object.pid
    end

    def id   ### Needed for the nested form helper
      self.pid
    end
    
    #return the internal fedora URI
    def internal_uri
      self.class.internal_uri(pid)
    end

    def self.internal_uri(pid)
      "info:fedora/#{pid}"
    end

    #return the owner id
    def owner_id
      Array(@inner_object.ownerId).first
    end
    
    def owner_id=(owner_id)
      @inner_object.ownerId=(owner_id)
    end

    def label
      Array(@inner_object.label).first
    end

    def state
      Array(@inner_object.state).first
    end

    #return the create_date of the inner object (unless it's a new object)
    def create_date
      if @inner_object.new?
        Time.now
      elsif @inner_object.respond_to? :createdDate
        Array(@inner_object.createdDate).first
      else
        @inner_object.profile['objCreateDate']
      end
    end

    #return the modification date of the inner object (unless it's a new object)
    def modified_date
      @inner_object.new? ? Time.now : Array(@inner_object.lastModifiedDate).first
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
  end

end
