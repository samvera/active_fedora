module ActiveFedora
  class ContentModel < Base
    CMODEL_NAMESPACE = "afmodel"
    CMODEL_PID_SUFFIX = ""
    
    attr_accessor :pid_suffix, :namespace
    
    def initialize(attrs={})
      @pid_suffix = attrs.has_key?(:pid_suffix) ? attrs[:pid_suffix] : CMODEL_PID_SUFFIX
      @namespace = attrs.has_key?(:namespace) ? attrs[:namespace] : CMODEL_NAMESPACE
      super
    end
    
    ###Override this, if you prefer your class names serialized some other way
    def self.sanitized_class_name(klass)
      klass.name.gsub(/(::)/, '_')
    end
    
    # list all of the models asserted by the provided object
    def self.models_asserted_by(obj)
      obj.relationships(:has_model)
    end
    
    def self.best_model_for(obj)
      best_model_match = obj.class unless obj.instance_of? ActiveFedora::Base

      known_models_for(obj).each do |model_value|
        # If this is of type ActiveFedora::Base, then set to the first found :has_model.
        best_model_match ||= model_value

        # If there is an inheritance structure, use the most specific case.
        if best_model_match > model_value
          best_model_match = model_value
        end
      end

      best_model_match
    end

    # returns an array of the model classes that are defined in the current 
    # application that the given object asserts (ie. if the object asserts 
    # a StreamingVideo model but the application doesn't define a 
    # StreamingVideo model, it will be excluded from this list.
    def self.known_models_for(obj)
      models_array = []
      models_asserted_by( obj ).each do |model_uri|
        m = uri_to_model_class(model_uri)
        if m
          models_array << m
        end
      end
      
      if models_array.empty?
        models_array = [default_model(obj)]
      end
      
      return models_array
    end

    ### Returns a ruby class to use if no other class could be find to instantiate
    ### Override this method if you need something other than the default strategy
    def self.default_model(obj)
      ActiveFedora::Base
    end
    
    
    # Returns an ActiveFedora Model class corresponding to the given uri if one can be found.
    # Returns false if no corresponding model can be found.
    def self.uri_to_model_class( uri )
      rc = Model.from_class_uri(uri)
      if rc && (rc.superclass == ActiveFedora::Base || rc.ancestors.include?(ActiveFedora::Base))
        rc
      else
        false
      end
    end
    
  end
end
