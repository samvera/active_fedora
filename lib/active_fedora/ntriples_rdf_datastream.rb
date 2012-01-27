require 'rdf'
require 'rdf/ntriples'

module ActiveFedora
  class NtriplesRDFDatastream < RDFDatastream

    def serialization_format
      :ntriples
    end

    def mimeType
      'text/plain'
    end

    def controlGroup
      'M'
    end
  end
end

