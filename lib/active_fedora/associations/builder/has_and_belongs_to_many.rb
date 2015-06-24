module ActiveFedora::Associations::Builder
  class HasAndBelongsToMany < CollectionAssociation #:nodoc:
    extend Deprecation
    self.macro = :has_and_belongs_to_many

    self.valid_options += [:inverse_of, :solr_page_size]

    def validate_options
      super
      Deprecation.warn HasAndBelongsToMany, ":solr_page_size doesn't do anything anymore and will be removed in ActiveFedora 10" if options.key?(:solr_page_size)
      if !options[:predicate]
        raise "You must specify a predicate for #{name}"
      elsif !options[:predicate].kind_of?(RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end
    end

  end
end
