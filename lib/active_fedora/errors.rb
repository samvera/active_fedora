module ActiveFedora #:nodoc:
  # Generic ActiveFedora exception class
  class ActiveFedoraError < StandardError
  end

  # Raised when ActiveFedora cannot find the record by given id or set of ids
  class ObjectNotFoundError < ActiveFedoraError
  end

  # Raised when attempting to access an attribute that has not been defined
  class UnknownAttributeError < NoMethodError
    attr_reader :record, :attribute

    def initialize(record, attribute, klass = nil)
      @record = record
      @attribute = attribute
      super("unknown attribute '#{attribute}' for #{klass || @record.class}.")
    end
  end

  # Raised when there is an error with the configuration files.
  class ConfigurationError < ActiveFedoraError
  end

  # Raised when an object assigned to an association has an incorrect type.
  #
  #   class Ticket < ActiveFedora::Base
  #     has_many :patches
  #   end
  #
  #   class Patch < ActiveFedora::Base
  #     belongs_to :ticket, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isComponentOf
  #   end
  #
  #   # Comments are not patches, this assignment raises AssociationTypeMismatch.
  #   @ticket.patches << Comment.new(content: "Please attach tests to your patch.")
  class AssociationTypeMismatch < ActiveFedoraError
  end

  class AssociationNotFoundError < ConfigurationError #:nodoc:
  end

  # This error is raised when trying to destroy a parent instance in N:1 or 1:1 associations
  # (has_many, has_one) when there is at least 1 child associated instance.
  # ex: if @project.tasks.size > 0, DeleteRestrictionError will be raised when trying to destroy @project
  class DeleteRestrictionError < ActiveFedoraError #:nodoc:
    def initialize(name = nil)
      if name
        super("Cannot delete record because of dependent #{name}")
      else
        super("Delete restriction error.")
      end
    end
  end

  # Raised by ActiveFedora::Base.save! and ActiveFedora::Base.create! methods when record cannot be
  # saved because record is invalid.
  class RecordNotSaved < ActiveFedoraError
  end

  # Raised by {ActiveFedora::Base#destroy!}[rdoc-ref:Persistence#destroy!]
  # when a call to {#destroy}[rdoc-ref:Persistence#destroy!]
  # would return false.
  #
  #   begin
  #     complex_operation_that_internally_calls_destroy!
  #   rescue ActiveFedora::RecordNotDestroyed => invalid
  #     puts invalid.record.errors
  #   end
  #
  class RecordNotDestroyed < ActiveFedoraError
    attr_reader :record

    def initialize(message = nil, record = nil)
      @record = record
      super(message)
    end
  end

  # Raised on attempt to update record that is instantiated as read only.
  class ReadOnlyRecord < ActiveFedoraError
  end

  # Raised when trying to initialize a record that already exists. ActiveFedora::Base.find should
  # be used instead
  class IllegalOperation < ActiveFedoraError
  end

  # Raised when the data has more than one statement for a predicate, but our constraints say it's singular
  # This helps to prevent overwriting multiple values with a single value when round tripping:
  #   class Book < ActiveFedora::Base
  #     property :title, predicate: RDF::Vocab::DC.title, multiple: false
  #   end
  #
  #   b = Book.new
  #   b.resource.title = ['foo', 'bar']
  #   b.title # Raises ConstraintError
  #   # which prevents us from doing:
  #   b.title = b.title
  class ConstraintError < ActiveFedoraError
  end

  # Used to rollback a transaction in a deliberate way without raising an exception.
  # Transactions are currently incomplete
  class Rollback < ActiveFedoraError
  end

  # Raised when Fedora returns a version without a create date
  class VersionLacksCreateDate < ActiveFedoraError
  end

  # Raised when you try to set a URI to an already persisted Base object.
  class AlreadyPersistedError < ActiveFedoraError
  end

  class DangerousAttributeError < ActiveFedoraError
  end
end
