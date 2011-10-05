module ActiveFedora
  class DatastreamHash < Hash
    
    def initialize (obj)
      @obj = obj
      super()
    end

    def [] (key)
      if key == 'DC' && !has_key?(key)
        ds = Datastream.new(@obj.inner_object, key, true)
        ds.content
        self[key] = ds
      end
      super
    end 
  end
end
