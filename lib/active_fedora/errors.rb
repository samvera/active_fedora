module ActiveFedora #:nodoc:

  # Generic ActiveFedora exception class
  class ActiveFedoraError < StandardError
  end

  # Raised when ActiveFedora cannot find the record by given id or set of ids
  class ObjectNotFoundError < ActiveFedoraError
  end

  # Raised when attempting to access an attribute that has not been defined
  class UnknownAttributeError < NoMethodError
  end

  # Raised when there is an error with the configuration files.
  class ConfigurationError < ActiveFedoraError
  end

  # Raised when ActiveFedora cannot find the predicate mapping configuration file
  class PredicateMappingsNotFoundError < ConfigurationError
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

  # Raised when ActiveFedora cannot find the predicate corresponding to the given property
  # in the predicate registy
  class UnregisteredPredicateError < ActiveFedoraError
  end

  # Raised by ActiveFedora::Base.save! and ActiveFedora::Base.create! methods when record cannot be
  # saved because record is invalid.
  class RecordNotSaved < ActiveFedoraError
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
  #     property :title, predicate: RDF::DC.title, multiple: false
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
end
