module ActiveFedora

  # Attributes delegated to ActiveTriples. Allows ActiveFedora to track all attributes consistently.
  #
  # @example
  #   class Book < ActiveFedora::Base
  #     property :title, predicate: ::RDF::DC.title
  #     property :author, predicate: ::RDF::DC.creator
  #   end
  #
  #   Book.attribute_names
  #   => ["title", "author"]

  class ActiveTripleAttribute < DelegatedAttribute
  end

end
