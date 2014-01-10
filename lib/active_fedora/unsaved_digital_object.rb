module ActiveFedora
  # Helps Rubydora create datastreams of the type defined by the ActiveFedora::Base#datastream_class_for_name
  class UnsavedDigitalObject 
    include DigitalObject::DatastreamBootstrap
    attr_accessor :original_class, :ownerId, :state, :datastreams, :label, :namespace

    PLACEHOLDER = nil
    
    def initialize(original_class, namespace, pid=nil)
      @pid = pid
      self.original_class = original_class
      self.namespace = namespace
      self.datastreams = {}
    end

    def pid
      @pid || PLACEHOLDER
    end

    def uri
      "unsaved:#{pid}"
    end

    # Set the pid.  This method is only avaialable before the object has been persisted in fedora.
    def pid=pid
      @pid = pid
    end

    def new_record?
      true
    end

    alias :new? :new_record?

    ### Change this into a real digital object
    def save
      obj = DigitalObject.find_or_initialize(self.original_class, assign_pid)
      self.datastreams.each do |k, v|
        v.digital_object = obj
        obj.datastreams[k] = v
      end
      obj.ownerId = ownerId if ownerId
      obj.label = label if label
      obj.state = state if state
      obj
    end

    def assign_pid
        return @pid if @pid
        self.original_class.assign_pid(self)
    end

    def delete
      #nop
    end
  end
end

