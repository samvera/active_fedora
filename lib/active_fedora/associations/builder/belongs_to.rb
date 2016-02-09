module ActiveFedora::Associations::Builder
  class BelongsTo < SingularAssociation #:nodoc:
    self.macro = :belongs_to

    def validate_options
      super
      raise "You must specify a predicate for #{name}" unless options[:predicate]
      raise ArgumentError, "Predicate must be a kind of RDF::URI" unless options[:predicate].is_a?(RDF::URI)
    end
  end
end
