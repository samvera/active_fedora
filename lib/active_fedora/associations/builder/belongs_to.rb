module ActiveFedora::Associations::Builder
  class BelongsTo < SingularAssociation #:nodoc:
    self.macro = :belongs_to

    def validate_options
      super
      if !options[:predicate]
        raise "You must specify a predicate for #{name}"
      elsif !options[:predicate].kind_of?(RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end
    end
  end
end
