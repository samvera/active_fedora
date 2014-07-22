require 'forwardable'

module ActiveFedora
  class DatastreamHash
    extend Forwardable

    def_delegators :@hash, *(Hash.instance_methods(false))
    
    def initialize (&block)
      @hash = Hash.new &block
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
