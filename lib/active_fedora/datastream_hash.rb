module ActiveFedora
  class DatastreamHash < Hash
    
    def initialize (obj)
      @obj = obj
      super()
    end

    def [] (key)
      if key == 'DC' && !has_key?(key)
        ds = Datastream.new(@obj.inner_object, key, :controlGroup=>'X')
        self[key] = ds
      end
      super
    end 

    def []= (key, val)
      @obj.inner_object.datastreams[key]=val# unless @obj.inner_object.new?
      super
    end 

    def freeze
      each_value do |datastream|
        datastream.freeze
      end
      super
    end
  end
end
