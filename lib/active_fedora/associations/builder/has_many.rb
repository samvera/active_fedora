module ActiveFedora::Associations::Builder
  class HasMany < CollectionAssociation #:nodoc:
    self.macro = :has_many

    self.valid_options += [:as, :dependent, :inverse_of]

    def build
      reflection = super
      configure_dependency
      reflection
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

    private

      def configure_dependency
        if options[:dependent]
          unless [:destroy, :delete_all, :nullify, :restrict].include?(options[:dependent])
            raise ArgumentError, "The :dependent option expects either :destroy, :delete_all, " \
                                 ":nullify or :restrict (#{options[:dependent].inspect})"
          end

          send("define_#{options[:dependent]}_dependency_method")
          model.before_destroy dependency_method_name
        end
      end

      def define_destroy_dependency_method
        name = self.name
        model.send(:define_method, dependency_method_name) do
          send(name).delete_all
        end
      end

      def define_delete_all_dependency_method
        name = self.name
        model.send(:define_method, dependency_method_name) do
          send(name).delete_all
        end
      end
      alias :define_nullify_dependency_method :define_delete_all_dependency_method

      def define_restrict_dependency_method
        name = self.name
        model.send(:define_method, dependency_method_name) do
          raise ActiveRecord::DeleteRestrictionError.new(name) unless send(name).empty?
        end
      end

      def dependency_method_name
        "has_many_dependent_for_#{name}"
      end
  end
end
