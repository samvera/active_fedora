module ActiveFedora::Associations::Builder
  class BelongsTo < SingularAssociation #:nodoc:
    self.macro = :belongs_to

    def validate_options
      super
      if !options[:property] && !options[:predicate]
        raise "You must specify a predicate for #{name}"
      end
      if options[:property]
        Deprecation.warn BelongsTo, "the :property option to belongs_to is deprecated and will be removed in active-fedora 10.0. Use :predicate instead", caller(5)
      end
      if options[:predicate] && !options[:predicate].kind_of?(::RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end

    end
  end
end
