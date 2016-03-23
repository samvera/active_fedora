module ActiveFedora::Associations::Builder
  class HasMany < CollectionAssociation #:nodoc:
    def self.macro
      :has_many
    end

    def self.valid_options(options)
      super + [:as, :dependent, :inverse_of]
    end

    def self.valid_dependent_options
      [:destroy, :delete_all, :nullify, :restrict_with_error, :restrict_with_exception]
    end

    def self.define_readers(mixin, name)
      super

      mixin.redefine_method("#{name.to_s.singularize}_ids") do
        association(name).ids_reader
      end
    end

    def self.define_writers(mixin, name)
      super

      mixin.redefine_method("#{name.to_s.singularize}_ids=") do |ids|
        association(name).ids_writer(ids)
      end
    end
  end
end
