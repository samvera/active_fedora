module ActiveFedora
  class DigitalObject
    attr_accessor :original_class
    
    module DatastreamBootstrap
      def datastream_object_for dsid, options={}, ds_spec=nil
        # ds_spec is nil when called from Rubydora for existing datastreams, so it should not be autocreated
        ds_spec ||= (original_class.ds_specs[dsid] || {}).merge(:autocreate=>false)
        ds = ds_spec.fetch(:type, ActiveFedora::Datastream).new(self, dsid, options)
        ds.default_attributes = {}
        if ds_spec[:autocreate]
          ds.datastream_will_change!
        end
        ds
      end
    end    
    include DatastreamBootstrap

    def self.find_or_initialize(original_class, pid)
      conn = original_class.connection_for_pid(pid)
      obj = super(pid, conn)
      obj.original_class = original_class
      obj
    end
  end
end
