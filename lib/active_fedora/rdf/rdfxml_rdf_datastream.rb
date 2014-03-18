require 'rdf/rdfxml'

module ActiveFedora
  class RdfxmlRDFDatastream < RDFDatastream
    def serialization_format
      :rdfxml 
    end

    def self.default_attributes
      super.merge(:mimeType => 'text/xml')
    end
  end
end
