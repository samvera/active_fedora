SOLR_DOCUMENT_ID = "id" unless (defined?(SOLR_DOCUMENT_ID) && !SOLR_DOCUMENT_ID.nil?)
ENABLE_SOLR_UPDATES = true unless defined?(ENABLE_SOLR_UPDATES)
require 'active_support/descendants_tracker'
require 'active_fedora/errors'
require 'active_fedora/log_subscriber'

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
  # Attached files defined with +contains+ are accessed via the +attached_files+ member hash.
  #
  class Base
    extend ActiveModel::Naming
    extend ActiveSupport::DescendantsTracker
    extend LdpCache::ClassMethods

    include Core
    include Identifiable
    include Persistence
    include Indexing
    include Scoping
    include ActiveModel::Conversion
    include Callbacks
    include Validations
    extend Querying
    include Associations
    include AutosaveAssociation
    include NestedAttributes
    include Reflection
    include Serialization

    include AttachedFiles
    include FedoraAttributes
    include AttributeMethods
    include Attributes
    include Versionable
    include LoadableFromJson
    include Schema
    include Pathing
  end

  ActiveSupport.run_load_hooks(:active_fedora, Base)
end
