require 'rdf/ntriples'

module ActiveFedora
  class NtriplesRDFDatastream < RDFDatastream
    def self.default_attributes
      super.merge(:mimeType => 'text/plain')
    end

    def serialization_format
      :ntriples
    end
  end
end

