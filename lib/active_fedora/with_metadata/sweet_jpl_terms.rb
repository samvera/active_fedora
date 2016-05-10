require 'rdf'
module ActiveFedora::WithMetadata
  class SweetJPLTerms < RDF::StrictVocabulary('http://sweet.jpl.nasa.gov/2.2/reprDataFormat.owl#')
    # Property definitions
    property :byteOrder,
             comment: ['Byte Order.'.freeze],
             range: 'xsd:string'.freeze,
             label: 'Byte Order'.freeze
  end
end
