require 'rdf'
class ActiveFedora::RDF::RelsExt < RDF::StrictVocabulary("http://fedora.info/definitions/v4/rels-ext#")
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
