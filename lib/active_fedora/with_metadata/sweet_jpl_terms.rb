# frozen_string_literal: true
require 'rdf'
module ActiveFedora::WithMetadata
  class SweetJPLTerms < RDF::StrictVocabulary('http://sweet.jpl.nasa.gov/2.2/reprDataFormat.owl#')
    # Property definitions
    property :byteOrder,
             comment: ['Byte Order.'],
             range: 'xsd:string',
             label: 'Byte Order'
  end
end
