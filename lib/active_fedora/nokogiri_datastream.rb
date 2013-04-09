#this class represents a xml metadata datastream
module ActiveFedora
  class NokogiriDatastream < OmDatastream
    extend Deprecation
    def initialize(digital_object=nil, dsid=nil, options={})
      Deprecation.warn(self.class, "NokogiriDatastream is deprecated and will be removed in hydra-head 7.0. Use OmDatastream insead.", caller(2))
      super
    end
  end
end

