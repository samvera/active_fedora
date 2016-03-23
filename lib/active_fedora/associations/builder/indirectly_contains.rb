module ActiveFedora::Associations::Builder
  class IndirectlyContains < CollectionAssociation #:nodoc:
    def self.macro
      :indirectly_contains
    end

    def self.valid_options(options)
      super + [:has_member_relation, :is_member_of_relation, :inserted_content_relation, :foreign_key, :through] - [:predicate]
    end

    def self.define_readers(mixin, name)
      super

      mixin.redefine_method("#{name.to_s.singularize}_ids") do
        association(name).ids_reader
      end
    end

    def self.validate_options(options)
      super
      if !options[:has_member_relation] && !options[:is_member_of_relation]
        raise ArgumentError, "You must specify a predicate for #{name}"
      elsif !options[:has_member_relation].is_a?(RDF::URI) && !options[:is_member_of_relation].is_a?(RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end

      raise ArgumentError, "Missing :through option" unless options[:through]
      raise ArgumentError, "Missing :foreign_key option" unless options[:foreign_key]
    end
  end
end
