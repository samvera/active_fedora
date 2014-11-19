require 'rdf'
class ActiveFedora::RDF::FedoraRelsExt < RDF::StrictVocabulary("http://www.fedora.info/definitions/1/0/fedora-relsext-ontology.rdfs#")
  property :hasAnnotation
  property :hasCollectionMember
  property :hasConstituent
  property :hasDependent
  property :hasDerivation
  property :hasDescription
  property :hasEquivalent
  property :hasExternalContent
  property :hasMember
  property :hasMetadata
  property :hasPart
  property :hasSubset
  property :isAnnotationOf
  property :isConstituentOf
  property :isDependentOf
  property :isDerivationOf
  property :isDescriptionOf
  property :isExternalContentOf
  property :isMemberOf
  property :isMemberOfCollection
  property :isMetadataFor
  property :isPartOf
  property :isSubsetOf
end
