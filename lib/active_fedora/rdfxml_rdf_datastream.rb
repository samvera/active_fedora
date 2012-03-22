require 'rdf/rdfxml'

module ActiveFedora
  class RdfxmlRDFDatastream < RDFDatastream
    def serialization_format
      :rdfxml 
    end

    def mimeType
      'text/xml'
    end

    def controlGroup
      'M'
    end
  end
end
