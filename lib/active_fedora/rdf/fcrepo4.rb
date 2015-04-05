require 'rdf'
module ActiveFedora::RDF
  class Fcrepo4 < RDF::StrictVocabulary("http://fedora.info/definitions/v4/repository#")
    property :created
    property :digest
    property :hasVersion
    property :hasVersionLabel
    property :lastModified
    property :status
    property :ServerManaged
  end
end
