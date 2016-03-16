module ActiveFedora
  # = ActiveFedora
  # This module mixes various methods into the including class,
  # much in the way ActiveRecord does.
  module Model
    # @deprecated
    # Convenience method for getting class constant based on a string
    # @example
    #   ActiveFedora::Model.class_from_string("Om")
    #   => Om
    #   ActiveFedora::Model.class_from_string("ActiveFedora::RdfNode::TermProxy")
    #   => ActiveFedora::RdfNode::TermProxy
    # @example Search within ActiveFedora::RdfNode for a class called "TermProxy"
    #   ActiveFedora::Model.class_from_string("TermProxy", ActiveFedora::RdfNode)
    #   => ActiveFedora::RdfNode::TermProxy
    def self.class_from_string(*args)
      Deprecation.warn("ActiveFedora::Model.class_from_string has been deprecated and will be removed in ActiveFedora 10.0. Use ActiveFedora::ModelClassifier.class_from_string instead")
      ActiveFedora::ModelClassifier.class_from_string(*args)
    end

    # @deprecated
    # Takes a Fedora URI for a cModel, and returns a
    # corresponding Model if available
    # This method should reverse ClassMethods#to_class_uri
    # @return [Class, False] the class of the model or false, if it does not exist
    def self.from_class_uri(model_value)
      Deprecation.warn("ActiveFedora::Model.from_class_uri has been deprecated and will be removed in ActiveFedora 10.0. Use ActiveFedora::ModelClassifier.from_class_uri instead")
      ActiveFedora::ModelClassifier.new(Array(model_value)).best_model
    end
  end
end
