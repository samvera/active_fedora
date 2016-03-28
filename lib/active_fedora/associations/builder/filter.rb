module ActiveFedora::Associations::Builder
  class Filter < ActiveFedora::Associations::Builder::CollectionAssociation
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
  end
end
