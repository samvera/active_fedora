module ActiveFedora
  class SolrDigitalObject
    attr_accessor :pid, :label, :state, :ownerId, :attributes, :datastreams, :repository
    
    def initialize(attr)
      self.datastreams = {}
      self.attributes = attr
      self.label = attr['objLabel']
      self.state = attr['objState']
      self.ownerId = attr['objOwnerId']
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
