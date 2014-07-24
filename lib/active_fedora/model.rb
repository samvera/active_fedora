SOLR_DOCUMENT_ID = "id" unless defined?(SOLR_DOCUMENT_ID)

module ActiveFedora
  # = ActiveFedora
  # This module mixes various methods into the including class,
  # much in the way ActiveRecord does.  
  module Model 

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

    private 
    
    def self.class_exists?(class_name)
      return false if class_name.empty?
      klass = class_name.constantize
      return klass.is_a?(Class)
    rescue NameError
      return false
    end
    
  end
end
