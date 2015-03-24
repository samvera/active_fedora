require 'rdf/ntriples'

module ActiveFedora
  class NtriplesRDFDatastream < RDFDatastream
    def serialization_format
      :ntriples
    end
  end
end

