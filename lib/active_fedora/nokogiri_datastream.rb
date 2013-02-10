#this class represents a xml metadata datastream
module ActiveFedora
  class NokogiriDatastream < OmDatastream
    def initialize(digital_object=nil, dsid=nil, options={})
      Deprecation.warn("NokogiriDatastream is deprecated and will be removed in active-fedora 7.0, use OmDatastream instead", caller)
      super
    end
  end
end

