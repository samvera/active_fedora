module ActiveFedora
  # Helps Rubydora create datastreams of the type defined by the ActiveFedora::Base#datastream_class_for_name
  class DigitalObject < Rubydora::DigitalObject
    attr_accessor :original_class
    
    module DatastreamBootstrap
      def datastream_object_for dsid, options={}, ds_spec=nil
        # ds_spec is nil when called from Rubydora for existing datastreams, so it should not be autocreated
        ds_spec ||= (original_class.ds_specs[dsid] || {}).merge(:autocreate=>false)
        ds = ds_spec.fetch(:type, ActiveFedora::Datastream).new(self, dsid, options)
        attributes = {}
        attributes[:asOfDateTime] ||= asOfDateTime if self.respond_to? :asOfDateTime
        attributes[:dsLabel] = ds_spec[:label] if ds_spec[:label].present?
        attributes[:controlGroup] = ds_spec[:control_group] if ds_spec[:control_group].present?
        attributes[:versionable] = ds_spec[:versionable] unless ds_spec[:versionable].nil?
        if attributes[:controlGroup]=='E'
          if !ds_spec[:disseminator].present? && ds_spec[:url].present?
            attributes[:dsLocation]= ds_spec[:url]
          end
        elsif attributes[:controlGroup]=='R'
          attributes[:dsLocation]= ds_spec[:url]
        end
        ds.default_attributes = attributes
        # would rather not load profile here in the call to .new?, so trusting :autocreate attribute
        if ds_spec[:autocreate] # and ds.new?
          ds.datastream_will_change!
        end
        ds
      end
    end    
    include DatastreamBootstrap

    def self.find(original_class, pid)
      raise ActiveFedora::ObjectNotFoundError.new("Unable to find #{pid.inspect} in fedora. ") unless pid.present?
      conn = original_class.connection_for_pid(pid)
      obj = begin
        super(pid, conn)
      rescue Rubydora::RecordNotFound
        raise ActiveFedora::ObjectNotFoundError, "Unable to find '#{pid}' in fedora. See logger for details."
      end
      obj.original_class = original_class
      # PID is not found, but was "well-formed" for its Fedora request. So
      # an object is instantiated with that PID.
      raise ActiveFedora::ObjectNotFoundError, "Unable to find '#{pid}' in fedora" if obj.new?
      obj
    end

    def self.find_or_initialize(original_class, pid)
      conn = original_class.connection_for_pid(pid)
      obj = super(pid, conn)
      obj.original_class = original_class
      obj
    end
  end
end
