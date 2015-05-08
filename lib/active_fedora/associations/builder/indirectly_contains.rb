module ActiveFedora::Associations::Builder
  class IndirectlyContains < CollectionAssociation #:nodoc:
    self.macro = :indirectly_contains
    self.valid_options += [:has_member_relation, :is_member_of_relation, :inserted_content_relation, :foreign_key, :through]
    self.valid_options -= [:predicate]

    def build
      reflection = super
      configure_dependency
      reflection
    end

    def validate_options
      super
      if !options[:has_member_relation] && !options[:is_member_of_relation]
        raise ArgumentError, "You must specify a predicate for #{name}"
      elsif !options[:has_member_relation].kind_of?(RDF::URI) && !options[:is_member_of_relation].kind_of?(RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end

      raise ArgumentError, "Missing :through option" if !options[:through]
      raise ArgumentError, "Missing :foreign_key option" if !options[:foreign_key]
    end
  end
end

