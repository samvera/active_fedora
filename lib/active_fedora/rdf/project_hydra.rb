# -*- encoding: utf-8 -*-
require 'rdf'
class ActiveFedora::RDF::ProjectHydra < ::RDF::StrictVocabulary("http://projecthydra.org/ns/relations#")
  property :hasProfile,
           label: "Has Profile".freeze,
           subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
           type: "rdf:Property".freeze
  property :isGovernedBy,
           label: "Is Governed By".freeze,
           subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
           type: "rdf:Property".freeze
end
