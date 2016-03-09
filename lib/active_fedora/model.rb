SOLR_DOCUMENT_ID = "id".freeze unless defined?(SOLR_DOCUMENT_ID)

module ActiveFedora
  # = ActiveFedora
  # This module mixes various methods into the including class,
  # much in the way ActiveRecord does.
  module Model
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

    # Takes a Fedora URI for a cModel, and returns a
    # corresponding Model if available
    # This method should reverse ClassMethods#to_class_uri
    # @return [Class, False] the class of the model or false, if it does not exist
    def self.from_class_uri(model_value)
      unless class_exists?(model_value)
        ActiveFedora::Base.logger.warn "'#{model_value}' is not a real class" if ActiveFedora::Base.logger
        return nil
      end
      ActiveFedora.class_from_string(model_value)
    end

    def self.class_exists?(class_name)
      return false if class_name.empty?
      klass = class_name.constantize
      return klass.is_a?(Class)
    rescue NameError
      return false
    end
    private_class_method :class_exists?
  end
end
