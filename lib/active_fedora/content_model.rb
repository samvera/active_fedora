require 'facets/string/titlecase'
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
    
    ### TODO: Shouldn't this be the same as: klass.to_class_uri ?  - Justin
    def self.pid_from_ruby_class(klass,attrs={})

      unless klass.respond_to? :pid_suffix
        pid_suffix = attrs.has_key?(:pid_suffix) ? attrs[:pid_suffix] : CMODEL_PID_SUFFIX
      else
        pid_suffix = klass.pid_suffix
      end
      unless klass.respond_to? :pid_namespace
        namespace = attrs.has_key?(:namespace) ? attrs[:namespace] : CMODEL_NAMESPACE   
      else
        namespace = klass.pid_namespace
      end
      return "info:fedora/#{namespace}:#{sanitized_class_name(klass)}#{pid_suffix}" 
    end
    
    ###Override this, if you prefer your class names serialized some other way
    def self.sanitized_class_name(klass)
      klass.name.gsub(/(::)/, '_')
    end
    
    def self.models_asserted_by(obj)
      obj.ids_for_outbound(:has_model)
    end
    
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
    
    # Returns a ruby class corresponding to the given uri if one can be found.
    # Returns false if no corresponding class can be found.
    def self.uri_to_ruby_class( uri )
      classname = Model.classname_from_uri(uri)
      
      if class_exists?(classname)
        Kernel.const_get(classname)
      else
        false
      end
    end
    
    # Returns an ActiveFedora Model class corresponding to the given uri if one can be found.
    # Returns false if no corresponding model can be found.
    def self.uri_to_model_class( uri )
      rc = uri_to_ruby_class(uri)
      if rc && rc.superclass == ActiveFedora::Base
        rc
      else
        false
      end
    end
    
    private 
    
    def self.class_exists?(class_name)
      klass = Module.const_get(class_name)
      return klass.is_a?(Class)
    rescue NameError
      return false
    end
    
  end
end
