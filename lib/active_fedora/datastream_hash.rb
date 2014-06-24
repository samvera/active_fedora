require 'forwardable'

module ActiveFedora
  class DatastreamHash
    extend Forwardable

    def_delegators :@hash, *(Hash.instance_methods(false) - self.instance_methods(false))
    def_delegator  :@hash, :==
    
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

    def kind_of? (klass)
      super or @hash.kind_of?(klass)
    end
    alias_method :is_a?, :kind_of?
  end
end
