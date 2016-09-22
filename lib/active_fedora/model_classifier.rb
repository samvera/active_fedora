module ActiveFedora
  # Translate model names to classes
  class ModelClassifier
    # Convenience method for getting class constant based on a string
    # @example
    #   ActiveFedora::Model.class_from_string("Om")
    #   => Om
    #   ActiveFedora::Model.class_from_string("ActiveFedora::RdfNode::TermProxy")
    #   => ActiveFedora::RdfNode::TermProxy
    # @example Search within ActiveFedora::RdfNode for a class called "TermProxy"
    #   ActiveFedora::Model.class_from_string("TermProxy", ActiveFedora::RdfNode)
    #   => ActiveFedora::RdfNode::TermProxy
    def self.class_from_string(full_class_name, container_class = Kernel)
      container_class = container_class.name if container_class.is_a? Module
      container_parts = container_class.split('::')
      (container_parts + full_class_name.split('::')).flatten.inject(Kernel) do |mod, class_name|
        if mod == Kernel
          Object.const_get(class_name)
        elsif mod.const_defined? class_name.to_sym
          mod.const_get(class_name)
        else
          container_parts.pop
          class_from_string(class_name, container_parts.join('::'))
        end
      end
    end

    attr_reader :class_names, :default

    def initialize(class_names, default: ActiveFedora::Base)
      @class_names = Array(class_names)
      @default = default
    end

    ##
    # Convert all the provided class names to class instances
    def models
      class_names.map do |uri|
        classify(uri)
      end.compact
    end

    ##
    # Select the "best" class from the list of class names. We define
    #    the "best" class as:
    #     - a subclass of the given default, base class
    #     - preferring subclasses over the parent class
    def best_model(opts = {})
      best_model_match = opts.fetch(:default, default)

      models.each do |model_value|
        # If there is an inheritance structure, use the most specific case.
        best_model_match = model_value if best_model_match.nil? || best_model_match > model_value
      end

      best_model_match
    end

    private

      def classify(model_value)
        unless class_exists?(model_value)
          ActiveFedora::Base.logger.warn "'#{model_value}' is not a real class"
          return nil
        end
        ActiveFedora::ModelClassifier.class_from_string(model_value)
      end

      def class_exists?(class_name)
        return false if class_name.empty?
        klass = class_name.constantize
        return klass.is_a?(Class)
      rescue NameError
        return false
      end
  end
end
