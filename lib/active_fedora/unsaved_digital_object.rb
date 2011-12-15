module ActiveFedora
  # Helps Rubydora create datastreams of the type defined by the ActiveFedora::Base#datastream_class_for_name
  class UnsavedDigitalObject 
    attr_accessor :original_class, :datastreams, :label, :namespace
    
    def initialize(original_class, namespace)
      self.original_class = original_class
      self.namespace = namespace
      self.datastreams = {}
    end

    def pid
      '__DO_NOT_USE__'
    end

    def new?
      true
    end

    ### Change this into a real digital object
    def save
      obj = DigitalObject.find(self.original_class, assign_pid)
      self.datastreams.each do |k, v|
        v.digital_object = obj
        obj.datastreams[k] = v
      end
      obj
    end

    def assign_pid
        args = {}
        args[:namespace] = self.namespace if self.namespace
        RubydoraConnection.instance.nextid args
    end



  end
end

