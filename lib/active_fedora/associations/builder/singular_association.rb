module ActiveFedora::Associations::Builder
  class SingularAssociation < Association #:nodoc:
    def self.valid_options(options)
      super + [:dependent, :inverse_of, :required]
    end

    def self.define_accessors(model, reflection)
      super
      define_constructors(model.generated_association_methods, reflection.name) if reflection.constructable?
    end

    def self.define_constructors(mixin, name)
      mixin.redefine_method("build_#{name}") do |*params|
        association(name).build(*params)
      end

      mixin.redefine_method("create_#{name}") do |*params|
        association(name).create(*params)
      end

      mixin.redefine_method("create_#{name}!") do |*params|
        association(name).create!(*params)
      end
    end
  end
end
