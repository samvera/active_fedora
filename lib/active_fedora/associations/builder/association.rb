module ActiveFedora::Associations::Builder
  class Association #:nodoc:
    class_attribute :valid_options
    self.valid_options = [:class_name, :predicate, :type_validator]

    # Set by subclasses
    class_attribute :macro

    attr_reader :model, :name, :options, :mixin

    #configure_dependency
    def self.build(model, name, options)
      reflection = new(model, name, options).build
      define_accessors(model, reflection)
      define_callbacks(model, reflection)
      reflection
    end

    def initialize(model, name, options)
      @model, @name, @options = model, name, options
      translate_property_to_predicate
      validate_options
    end

    def build
      configure_dependency if options[:dependent] # see https://github.com/rails/rails/commit/9da52a5e55cc665a539afb45783f84d9f3607282
      model.create_reflection(self.class.macro, name, options, model)
    end

    def translate_property_to_predicate
      return unless options[:property]
      Deprecation.warn Association, "the :property option to `#{model}.#{macro} :#{name}' is deprecated and will be removed in active-fedora 10.0. Use :predicate instead", caller(5)
      options[:predicate] = predicate(options.delete(:property))
    end

    def validate_options
      options.assert_valid_keys(self.class.valid_options)
    end


    # Returns the RDF predicate as defined by the :property attribute
    def predicate(property)
      return property if property.kind_of? RDF::URI
      ActiveFedora::Predicates.find_graph_predicate(property)
    end

    def self.define_callbacks(model, reflection)
      if dependent = reflection.options[:dependent]
        check_dependent_options(dependent)
        add_destroy_callbacks(model, reflection)
      end
    end

    def self.define_accessors(model, reflection)
      mixin = model.generated_association_methods
      name = reflection.name
      define_readers(mixin, name)
      define_writers(mixin, name)
    end

    def self.define_readers(mixin, name)
      mixin.send(:define_method, name) do |*params|
        association(name).reader(*params)
      end
    end

    def self.define_writers(mixin, name)
      mixin.send(:define_method, "#{name}=") do |value|
        association(name).writer(value)
      end
    end

    def configure_dependency
      if options[:dependent]
        unless [:destroy, :delete].include?(options[:dependent])
          raise ArgumentError, "The :dependent option expects either :destroy or :delete (#{options[:dependent].inspect})"
        end

        method_name = "belongs_to_dependent_#{options[:dependent]}_for_#{name}"
        model.send(:class_eval, <<-eoruby, __FILE__, __LINE__ + 1)
          def #{method_name}
            association = #{name}
            association.#{options[:dependent]} if association
          end
        eoruby
        model.after_destroy method_name
      end
    end

  end
end
