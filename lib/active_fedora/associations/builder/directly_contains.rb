module ActiveFedora::Associations::Builder
  class DirectlyContains < CollectionAssociation #:nodoc:
    self.macro = :directly_contains
    self.valid_options += [:has_member_relation, :is_member_of_relation]
    self.valid_options -= [:predicate]

    def build
      reflection = super
      configure_dependency
      reflection
    end

    def validate_options
      super
      if !options[:has_member_relation] && !options[:is_member_of_relation]
        raise ArgumentError, "You must specify a :has_member_relation or :is_member_of_relation predicate for #{name}"
      elsif !options[:has_member_relation].kind_of?(RDF::URI) && !options[:is_member_of_relation].kind_of?(RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end
    end
  end
end

