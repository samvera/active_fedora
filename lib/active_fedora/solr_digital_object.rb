module ActiveFedora
  class SolrDigitalObject
    attr_accessor :pid, :attributes, :datastreams
    
    def initialize(attr)
      self.datastreams = {}
      self.attributes = attr
      self.pid = attr[:pid]
    end

    def new?
      false
    end

    def profile
      attributes
    end
  end
end
