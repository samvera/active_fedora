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
    
    def self.pid_from_ruby_class(klass,attrs={})
      sanitized_class_name = klass.name.gsub(/(::)/, '_')
      pid_suffix = attrs.has_key?(:pid_suffix) ? attrs[:pid_suffix] : CMODEL_PID_SUFFIX
      namespace = attrs.has_key?(:namespace) ? attrs[:namespace] : CMODEL_NAMESPACE   
      return "#{namespace}:#{sanitized_class_name}#{pid_suffix}" 
    end
    
  end
end