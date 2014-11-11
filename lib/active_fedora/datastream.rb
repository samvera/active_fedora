module ActiveFedora
  class Datastream < File
    extend Deprecation

    def self.inherited(child)
      Deprecation.warn child, "ActiveFedora::Datastream is deprecated and will be removed in active-fedora 10.0. Use ActiveFedora::File instead"
    end
  end
end
