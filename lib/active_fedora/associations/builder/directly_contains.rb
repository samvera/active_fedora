# frozen_string_literal: true
module ActiveFedora::Associations::Builder
  class DirectlyContains < CollectionAssociation # :nodoc:
    def self.macro
      :directly_contains
    end

    def self.valid_options(options)
      super + [:has_member_relation, :is_member_of_relation] - [:predicate]
    end

    def self.validate_options(options)
      super

      has_member_relation = options[:has_member_relation]
      is_member_of_relation = options[:is_member_of_relation]
      raise ArgumentError, "You must specify a :has_member_relation or :is_member_of_relation predicate for #{name}" if !has_member_relation && !is_member_of_relation
      raise ArgumentError, "Predicate must be a kind of RDF::URI" if !has_member_relation.is_a?(RDF::URI) && !is_member_of_relation.is_a?(RDF::URI)
    end
  end
end
