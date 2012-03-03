module ActiveFedora
  # Helps Rubydora create datastreams of the type defined by the ActiveFedora::Base#datastream_class_for_name
  class DigitalObject < Rubydora::DigitalObject
    attr_accessor :original_class
    
    def self.find(original_class, pid)
      conn = original_class.connection_for_pid(pid)
      obj = super(pid, conn)
      obj.original_class = original_class
      obj
    end

    def datastream_object_for dsid
      klass = original_class.datastream_class_for_name(dsid)
      klass.new self, dsid
    end
    
  end
end
