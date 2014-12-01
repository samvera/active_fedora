require 'rdf'
module ActiveFedora::RDF
  class Fcrepo4 < RDF::StrictVocabulary("http://fedora.info/definitions/v4/repository#")
    property :created
    property :lastModified
  end
end
