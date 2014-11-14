module ActiveFedora::Associations::Builder
  class BelongsTo < SingularAssociation #:nodoc:
    self.macro = :belongs_to

    self.valid_options += [:touch]

    def validate_options
      super
      if !options[:property] && !options[:predicate]
        raise "You must specify a predicate for #{name}"
      end
      if options[:property]
        Deprecation.warn BelongsTo, "the :property option to belongs_to is deprecated and will be removed in active-fedora 10.0. Use :predicate instead", caller(5)
      end
      if options[:predicate] && !options[:predicate].kind_of?(RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end

    end

    def self.define_callbacks(model, reflection)
      super
      add_counter_cache_callbacks(model, reflection) if reflection.options[:counter_cache]
      add_touch_callbacks(model, reflection)         if reflection.options[:touch]
    end

    def self.add_counter_cache_callbacks(model, reflection)
      cache_column = reflection.counter_cache_column
      name         = self.name

      method_name = "belongs_to_counter_cache_after_create_for_#{name}"
      mixin.redefine_method(method_name) do
        record = send(name)
        record.class.increment_counter(cache_column, record.id) unless record.nil?
      end
      model.after_create(method_name)

      method_name = "belongs_to_counter_cache_before_destroy_for_#{name}"
      mixin.redefine_method(method_name) do
        record = send(name)
        record.class.decrement_counter(cache_column, record.id) unless record.nil?
      end
      model.before_destroy(method_name)

      model.send(:module_eval,
        "#{reflection.class_name}.send(:attr_readonly,\"#{cache_column}\".intern) if defined?(#{reflection.class_name}) && #{reflection.class_name}.respond_to?(:attr_readonly)", __FILE__, __LINE__
      )
    end

    def self.add_touch_callbacks(model, reflection)
      name        = self.name
      method_name = "belongs_to_touch_after_save_or_destroy_for_#{name}"
      touch       = options[:touch]

      mixin.redefine_method(method_name) do
        record = send(name)

        unless record.nil?
          if touch == true
            record.touch
          else
            record.touch(touch)
          end
        end
      end

      model.after_save(method_name)
      model.after_touch(method_name)
      model.after_destroy(method_name)
    end
  end
end
