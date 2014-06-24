require 'forwardable'

module ActiveFedora
  class DatastreamHash
    extend Forwardable

    def_delegators :@hash, *(Hash.instance_methods(false))
    
    def initialize (obj, &block)
      @obj = obj
      @hash = Hash.new &block
    end

    def [] (key)
      if key == 'DC' && !has_key?(key)
        ds = Datastream.new(@obj.inner_object, key, :controlGroup=>'X')
        self[key] = ds
      end
      @hash[key]
    end 

    def []= (key, val)
      @obj.inner_object.datastreams[key]=val
      @hash[key]=val
    end

    def freeze
      each_value do |datastream|
        datastream.freeze
      end
      @hash.freeze
      super
    end
  end
end
