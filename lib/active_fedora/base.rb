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
  #     has_metadata "properties", type: ActiveFedora::SimpleDatastream do |m|
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
    extend ActiveModel::Naming
    extend ActiveSupport::DescendantsTracker
    include SemanticNode
    include Sharding
    include ActiveFedora::Persistence
    include Scoping
    include Loggable
    include Indexing
    include ActiveModel::Conversion
    include Validations
    include Callbacks
    include Datastreams
    extend Querying
    include Associations
    include AutosaveAssociation
    include NestedAttributes
    include Reflection
    include Attributes
    include Serialization
    include Core
    include FedoraAttributes
    include ReloadOnSave
    include Rdf::Identifiable
  end

end
