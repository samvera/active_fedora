module ActiveFedora::Associations::Builder
  class SingularAssociation < Association #:nodoc:
    self.valid_options += [:dependent, :counter_cache, :inverse_of]

    def constructable?
      true
    end

    def define_accessors
      super
      define_constructors if constructable?
    end

    private

      def define_constructors
        name = self.name

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
