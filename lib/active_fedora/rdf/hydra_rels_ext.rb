require 'rdf'
class ActiveFedora::RDF::HydraRelsExt < RDF::StrictVocabulary("http://projecthydra.org/ns/relations#")
  property :hasProfile
  property :isGovernedBy
end
