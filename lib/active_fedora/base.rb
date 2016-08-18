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
  #     property :creator, predicate: RDF::Vocab::DC.creator
  #   end
  #
  # The above example creates a Fedora object with a property named "creator"
  #
  # Attached files defined with +has_subresource+ and iis accessed via the +attached_files+ member hash.
  #
  class Base
    extend ActiveModel::Naming
    extend ActiveSupport::DescendantsTracker
    extend LdpCache::ClassMethods

    include AttributeAssignment
    include Core
    include Identifiable
    include Inheritance
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
    include Serialization

    include AttachedFiles
    include FedoraAttributes
    include Reflection
    include AttributeMethods
    include Attributes
    include Versionable
    include LoadableFromJson
    include Schema
    include Aggregation::BaseExtension
  end

  ActiveSupport.run_load_hooks(:active_fedora, Base)
end
