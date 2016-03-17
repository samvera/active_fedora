module ActiveFedora::Associations::Builder
  class Association #:nodoc:
    class << self
      attr_accessor :extensions
    end
    self.extensions = []

    VALID_OPTIONS = [:class_name, :predicate, :type_validator].freeze

    def self.macro
      raise NotImplementedError
    end

    def self.valid_options(_options)
      VALID_OPTIONS + Association.extensions.flat_map(&:valid_options)
    end

    def self.validate_options(options)
      options.assert_valid_keys(valid_options(options))
    end

    attr_reader :model, :name, :options, :mixin

    # configure_dependency
    def self.build(model, name, options, &block)
      if model.dangerous_attribute_method?(name)
        Deprecation.warn(ActiveFedora::Base, "You tried to define an association named #{name} on the model #{model.name}, but " \
                             "this will conflict with a method #{name} already defined by ActiveFedora. " \
                             "Please choose a different association name.")
      end

      extension = define_extensions model, name, &block
      reflection = new(model, name, options).build
      define_accessors(model, reflection)
      define_callbacks(model, reflection)
      define_validations model, reflection
      reflection
    end

    def initialize(model, name, options)
      @model = model
      @name = name
      @options = options
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
      self.class.validate_options(options)
    end

    # Returns the RDF predicate as defined by the :property attribute
    def predicate(property)
      return property if property.is_a? RDF::URI
      ActiveFedora::Predicates.find_graph_predicate(property)
    end

    def self.define_extensions(_model, _name)
    end

    def self.define_callbacks(model, reflection)
      if dependent = reflection.options[:dependent]
        check_dependent_options(dependent)
        add_destroy_callbacks(model, reflection)
      end

      Association.extensions.each do |extension|
        extension.build model, reflection
      end
    end

    # Defines the setter and getter methods for the association
    # class Post < ActiveRecord::Base
    #   has_many :comments
    # end
    #
    # Post.first.comments and Post.first.comments= methods are defined by this method...
    def self.define_accessors(model, reflection)
      mixin = model.generated_association_methods
      name = reflection.name
      define_readers(mixin, name)
      define_writers(mixin, name)
    end

    def self.define_readers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(*args)
          association(:#{name}).reader(*args)
        end
      CODE
    end

    def self.define_writers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}=(value)
          association(:#{name}).writer(value)
        end
      CODE
    end

    def self.define_validations(_model, _reflection)
      # noop
    end

    def self.add_destroy_callbacks(model, reflection)
      name = reflection.name
      model.before_destroy lambda { |o| o.association(name).handle_dependency }
    end

    def configure_dependency
      return unless options[:dependent]
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
