require 'rdf/rdfxml'

module ActiveFedora
  class RdfxmlRDFDatastream < RDFDatastream
    def serialization_format
      :rdfxml 
    end

    def mime_type 
      'text/xml'
    end
  end
end
