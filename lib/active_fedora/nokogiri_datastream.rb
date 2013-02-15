#this class represents a xml metadata datastream
module ActiveFedora
  class NokogiriDatastream < OmDatastream
    extend Deprecation
    def initialize(digital_object=nil, dsid=nil, options={})
      super
    end
    self.deprecation_horizon= "hydra-head 7.0"
    deprecation_deprecate :initialize
  end
end

