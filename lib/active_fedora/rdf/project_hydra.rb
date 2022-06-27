# -*- encoding: utf-8 -*-
# frozen_string_literal: true
require 'rdf'
class ActiveFedora::RDF::ProjectHydra < ::RDF::StrictVocabulary("http://projecthydra.org/ns/relations#")
  property :hasProfile,
           label: "Has Profile",
           subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
           type: "rdf:Property"
  property :isGovernedBy,
           label: "Is Governed By",
           subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
           type: "rdf:Property"
end
