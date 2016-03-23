module ActiveFedora::Associations::Builder
  class HasAndBelongsToMany < CollectionAssociation #:nodoc:
    extend Deprecation
    def self.macro
      :has_and_belongs_to_many
    end

    def self.valid_options(options)
      super + [:inverse_of, :solr_page_size]
    end

    def self.validate_options(options)
      super
      Deprecation.warn HasAndBelongsToMany, ":solr_page_size doesn't do anything anymore and will be removed in ActiveFedora 10" if options.key?(:solr_page_size)
      raise "You must specify a predicate for #{name}" unless options[:predicate]
      raise ArgumentError, "Predicate must be a kind of RDF::URI" unless options[:predicate].is_a?(RDF::URI)
    end
  end
end
