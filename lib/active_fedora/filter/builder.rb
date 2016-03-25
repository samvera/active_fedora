module ActiveFedora::Filter
  class Builder < ActiveFedora::Associations::Builder::CollectionAssociation
    def self.valid_options(options)
      super + [:extending_from, :condition]
    end

    def self.macro
      :filter
    end

    def self.define_readers(mixin, name)
      super
      mixin.redefine_method("#{name.to_s.singularize}_ids") do
        association(name).ids_reader
      end
    end

    def self.create_reflection(model, name, scope, options, extension = nil)
      unless name.is_a?(Symbol)
        name = name.to_sym
        Deprecation.warn(ActiveFedora::Base, "association names must be a Symbol")
      end
      validate_options(options)
      translate_property_to_predicate(options)

      scope = build_scope(scope, extension)
      name = better_name(name)

      ActiveFedora::Orders::Reflection.create(macro, name, scope, options, model)
    end
  end
end

