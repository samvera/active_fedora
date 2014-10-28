require 'rdf'
class ActiveFedora::Rdf::Ldp < RDF::StrictVocabulary("http://www.w3.org/ns/ldp#")
  # Property definitions
  property :contains
  property :member
end
