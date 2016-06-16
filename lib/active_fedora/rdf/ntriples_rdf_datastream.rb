require 'rdf/ntriples'

module ActiveFedora
  class NtriplesRDFDatastream < RDFDatastream
    def serialization_format
      :ntriples
    end

    def deprecation_warning
      Deprecation.warn(NtriplesRDFDatastream, "NtriplesRDFDatastream is deprecated and will be removed in ActiveFedora 11", caller(2))
    end
  end
end
