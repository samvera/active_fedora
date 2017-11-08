module ActiveFedora::Attributes
  class PropertyBuilder < ActiveTriples::PropertyBuilder #:nodoc:
    def self.define_accessors(model, reflection, options = {})
      if reflection.multiple?
        super
      else
        mixin = model.generated_property_methods
        name = reflection.term
        define_singular_readers(mixin, name)
        define_singular_id_reader(mixin, name) unless options[:cast] == false
        define_singular_writers(mixin, name)
      end
    end

    def self.define_writers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}=(value)
          if value.present? && !value.respond_to?(:each)
            raise ArgumentError, "You attempted to set the property `#{name}' of \#{id} to a scalar value. However, this property is declared as being multivalued."
          end
          set_value(:#{name}, value)
        end
      CODE
    end

    def self.define_singular_readers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(*args)
          vals = get_values(:#{name})
          return nil unless vals
          raise ActiveFedora::ConstraintError, "Expected \\"#{name}\\" of \#{id} to have 0-1 statements, but there are \#{vals.size}" if vals.size > 1
          vals.first
        end
      CODE
    end

    def self.define_singular_id_reader(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_id(*args)
          get_values(:#{name}, :cast => false)
        end
      CODE
    end

    def self.define_singular_writers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}=(value)
          if value.respond_to?(:each) # singular
            raise ArgumentError, "You attempted to set the property `#{name}' of \#{id} to an enumerable value. However, this property is declared as singular."
          end
          set_value(:#{name}, value)
        end
      CODE
    end

    def build(&block)
      # TODO: remove this block stuff
      NodeConfig.new(name, options[:predicate], options.except(:predicate)) do |config|
        config.with_index(&block) if block_given?
      end
    end
  end
end
