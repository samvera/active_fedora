require 'rdf'
class ActiveFedora::RDF::Fcrepo < RDF::StrictVocabulary("http://fedora.info/definitions/v4/repository#")

    # Property definitions
    property :hasContent, comment: %(Defining where the fedora object has content.)
    property :mimeType

    property :created
    property :lastModified
    property :hasChild

end
