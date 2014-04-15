module ActiveFedora::Associations::Builder
  class Association #:nodoc:
    class_attribute :valid_options
    self.valid_options = [:class_name, :property]

    # Set by subclasses
    class_attribute :macro

    attr_reader :model, :name, :options, :mixin

    def self.build(model, name, options)
      new(model, name, options).build
    end

    def initialize(model, name, options)
      @model, @name, @options = model, name, options
      @mixin = Module.new
      @model.__send__(:include, @mixin)
    end

    def build
      validate_options
      reflection = model.create_reflection(self.class.macro, name, options, model)
      define_accessors
      reflection
    end

    # Returns the RDF predicate as defined by the :property attribute
    def predicate
      predicate = options[:property]
      return predicate if predicate.kind_of? RDF::URI
      ActiveFedora::Predicates.find_graph_predicate(predicate)
    end


    private

      def validate_options
        options.assert_valid_keys(self.class.valid_options)
      end

      def define_accessors
        define_readers
        define_writers
      end

      def define_readers
        name = self.name

        mixin.send(:define_method, name) do |*params|
          association(name).reader(*params)
        end
      end

      def define_writers
        name = self.name

        mixin.send(:define_method, "#{name}=") do |value|
          association(name).writer(value)
        end
      end
  end
end
