module ActiveFedora
  class DatastreamHash < Hash
    def freeze
      each_value do |datastream|
        datastream.freeze
      end
      super
    end
  end
end
