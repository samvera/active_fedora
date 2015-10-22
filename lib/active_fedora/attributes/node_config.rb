module ActiveFedora::Attributes
  class NodeConfig < ActiveTriples::NodeConfig
    def multiple?
      @multiple
    end

    def initialize(term, predicate, options = {})
      super
      @multiple = options[:multiple]
    end
  end
end
