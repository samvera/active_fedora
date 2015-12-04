# -*- encoding: utf-8 -*-
# This file generated automatically using vocab-fetch from github.com:fcrepo3/fcrepo/master/fcrepo-server/src/main/resources/rdfs/fedora_relsext_ontology.rdfs
# and edited for clarity and additional terms published in different serializations of the voabularies
require 'rdf'
module ActiveFedora::RDF
  module Fcrepo
    class System < ::RDF::StrictVocabulary("info:fedora/fedora-system:")
      term :"ContentModel-3.0",
           comment: %(Base Fedora 3 CModel cModel).freeze,
           label: "Fedora 3 Content Model".freeze,
           subClassOf: "info:fedora/fedora-system:def/model#FedoraObject".freeze,
           type: "info:fedora/fedora-system:def/model#FedoraObject".freeze
      term :"FedoraObject-3.0",
           comment: %(Base Fedora 3 Object cModel).freeze,
           label: "Fedora 3 Object".freeze,
           subClassOf: "info:fedora/fedora-system:def/model#FedoraObject".freeze,
           type: "info:fedora/fedora-system:def/model#FedoraObject".freeze
      term :"ServiceDefinition-3.0",
           comment: %(Fedora 3 Service Definition/BDef cModel).freeze,
           label: "Fedora 3 Service Definition".freeze,
           subClassOf: "info:fedora/fedora-system:def/model#FedoraObject".freeze,
           type: "info:fedora/fedora-system:def/model#FedoraObject".freeze
      term :"ServiceDeployment-3.0",
           comment: %(Fedora 3 Service Deployment/BMech cModel).freeze,
           label: "Fedora 3 Service Deployment".freeze,
           subClassOf: "info:fedora/fedora-system:def/model#FedoraObject".freeze,
           type: "info:fedora/fedora-system:def/model#FedoraObject".freeze
    end
    class Model < ::RDF::StrictVocabulary("info:fedora/fedora-system:def/model#")
      # Class definitions
      term :FedoraObject,
           comment: %(The base type of all objects in Fedora).freeze,
           label: "FedoraObject".freeze,
           subClassOf: "rdfs:Resource".freeze,
           type: "rdfs:Class".freeze
      term :Datastream,
           comment: %(Binary data associated with a Fedora object).freeze,
           label: "Datastream".freeze,
           subClassOf: "rdfs:Resource".freeze,
           type: "rdfs:Class".freeze
      term :ExtProperty,
           comment: %(Reification of an extension property of a Fedora object used in messaging).freeze,
           label: "ExtProperty".freeze,
           subClassOf: "rdf:Property".freeze,
           type: "rdfs:Class".freeze
      term :State,
           comment: %(The state of a Fedora object or datastream).freeze,
           label: "State".freeze,
           subClassOf: "rdfs:Resource".freeze,
           type: "rdfs:Class".freeze
      term :Active,
           comment: %(State of an object available in the repository).freeze,
           label: "Active".freeze,
           subClassOf: "rdfs:Resource".freeze,
           type: "info:fedora/fedora-system:def/model#State".freeze
      term :Deleted,
           comment: %(State of an object that should be considered deleted, but is not purged).freeze,
           label: "Deleted".freeze,
           subClassOf: "rdfs:Resource".freeze,
           type: "info:fedora/fedora-system:def/model#State".freeze
      term :Inactive,
           comment: %(State of an object that should be considered temporarily unavailable).freeze,
           label: "Inactive".freeze,
           subClassOf: "rdfs:Resource".freeze,
           type: "info:fedora/fedora-system:def/model#State".freeze
      # Property definitions
      property :altIds,
               comment: %(The alternate IDs for a datastream).freeze,
               label: "Alternate IDs".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string".freeze,
               type: "rdf:Property".freeze
      property :controlGroup,
               comment: %(indicates whether a Datastream's content is inline XML (X), Managed (M), Referenced (R) or External (E)).freeze,
               label: "controlGroup".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string".freeze,
               type: "rdf:Property".freeze
      property :createdDate,
               comment: %(The UTC datetime an object was created).freeze,
               label: "createdDate".freeze,
               domain: "info:fedora/fedora-system:def/model#FedoraObject",
               range: "xsd:dateTimeStamp".freeze,
               type: "rdf:Property".freeze
      property :definesMethod,
               comment: %(indicates the name of a service method defined in this interface).freeze,
               label: "definesMethod".freeze,
               domain: "info:fedora/fedora-system:ServiceDefinition-3.0".freeze,
               range: "xsd:NCName".freeze,
               type: "rdf:Property".freeze
      property :digest,
               comment: %(indicates the checksum digest of a datastream's contents or the keyword 'none').freeze,
               label: "digest".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string".freeze,
               type: "rdf:Property".freeze
      property :digestType,
               comment: %(indicates either the checksum algorithm or the keyword DISABLED).freeze,
               label: "digestType".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string".freeze,
               type: "rdf:Property".freeze
      property :downloadFilename,
               comment: %(indicates the name to be used when downloading a datastream's contents).freeze,
               label: "downloadFilename".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string".freeze,
               type: "rdf:Property".freeze
      property :extProperty,
               comment: %(indicates an extension property of an object in Fedora in messaging).freeze,
               label: "extProperty".freeze,
               domain: "info:fedora/fedora-system:def/model#FedoraObject".freeze,
               range: "info:fedora/fedora-system:def/model#ExtProperty".freeze,
               type: "rdf:Property".freeze
      property :formatURI,
               comment: %(A URI indicating the format of a datastream's content).freeze,
               label: "formatURI".freeze,
               type: "rdf:Property".freeze
      property :hasModel,
               comment: %(Indicates the Fedora 3 CModels for this object).freeze,
               label: "hasModel".freeze,
               subPropertyOf: "rdf:type".freeze,
               domain: "info:fedora/fedora-system:FedoraObject-3.0".freeze,
               range: "info:fedora/fedora-system:ContentModel-3.0".freeze,
               type: "rdf:Property".freeze
      property :hasService,
               comment: %(indicates the Fedora 3 Service Definitions applicable to this CModel).freeze,
               label: "hasService".freeze,
               domain: "info:fedora/fedora-system:ContentModel-3.0".freeze,
               range: "info:fedora/fedora-system:ServiceDefinition-3.0".freeze,
               type: "rdf:Property".freeze
      property :isContractorOf,
               comment: %(indicates the Fedora 3 Content Models this deployment applies to).freeze,
               label: "".freeze,
               domain: "info:fedora/fedora-system:ServiceDeployment-3.0".freeze,
               range: "info:fedora/fedora-system:ContentModel-3.0".freeze,
               type: "rdf:Property".freeze
      property :isDeploymentOf,
               comment: %(indicates the Fedora 3 Service Definitions this deployment implements).freeze,
               label: "isDeploymentOf".freeze,
               domain: "info:fedora/fedora-system:ServiceDeployment-3.0".freeze,
               range: "info:fedora/fedora-system:ServiceDefinition-3.0".freeze,
               type: "rdf:Property".freeze
      property :label,
               comment: %(The label applied to a Fedora object).freeze,
               label: "label".freeze,
               domain: "info:fedora/fedora-system:def/model#FedoraObject".freeze,
               range: "xsd:string".freeze,
               type: "rdf:Property".freeze
      property :length,
               comment: %(indicates the length of a datastream's contents).freeze,
               label: "length".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream".freeze,
               range: "xsd:nonNegativeInteger".freeze,
               type: "rdf:Property".freeze
      property :ownerId,
               comment: %(indicates the owner of an object).freeze,
               label: "ownerId".freeze,
               type: "rdf:Property".freeze
      property :PID,
               comment: %(the Fedora 3 PID for an object).freeze,
               label: "PID".freeze,
               domain: "info:fedora/fedora-system:def/model#FedoraObject".freeze,
               range: "xsd:string".freeze,
               type: "rdf:Property".freeze
      property :state,
               comment: %(indicates the state of the object or datastream).freeze,
               label: "state".freeze,
               domain: ["info:fedora/fedora-system:def/model#FedoraObject".freeze, "info:fedora/fedora-system:def/model#Datastream".freeze],
               range: "info:fedora/fedora-system:def/model#State".freeze,
               type: "rdf:Property".freeze
      property :versionable,
               comment: %(indicates whether a datastream's property and contents changes are being tracked as versions).freeze,
               label: "versionable".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream".freeze,
               range: "xsd:boolean".freeze,
               type: "rdf:Property".freeze
    end
    class RelsExt < ::RDF::StrictVocabulary("info:fedora/fedora-system:def/relations-external#")
      # Property definitions
      property :fedoraRelationship,
               comment: %(The primitive property for all object-to-object relationships in the fedora ontology).freeze,
               label: "Fedora Relationship".freeze,
               type: "rdf:Property".freeze
      property :hasAnnotation,
               comment: %(A refinement of the generic descriptive relationship indicating a commentary relationship between fedora objects.  The subject is a fedora object that is being commented on and the predicate is a fedora object that represents an annotation or comment about the subject. ).freeze,
               label: "Has Annotation".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasDescription".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isAnnotationOf).freeze,
               type: "rdf:Property".freeze
      property :hasCollectionMember,
               label: "Has Collection Member".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasMember".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMemberOfCollection).freeze,
               type: "rdf:Property".freeze
      property :hasConstituent,
               label: "Has Constituent".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasPart".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isConstituentOf).freeze,
               type: "rdf:Property".freeze
      property :hasDependent,
               label: "Has Dependent".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDependentOf).freeze,
               type: "rdf:Property".freeze
      property :hasDerivation,
               label: "Has Derivation".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDerivationOf).freeze,
               type: "rdf:Property".freeze
      property :hasDescription,
               comment: %(A generic descriptive relationship between fedora objects.  The subject is a fedora object that is being described in some manner and the predicate is a fedora object that represents a descriptive entity that is about the subject. ).freeze,
               label: "Has Description".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDescriptionOf).freeze,
               type: "rdf:Property".freeze
      property :hasEquivalent,
               label: "Has Equivalent".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               type: "rdf:Property".freeze
      property :hasMember,
               label: "Has Member".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasPart/".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMemberOf).freeze,
               type: "rdf:Property".freeze
      property :hasMetadata,
               comment: %(A refinement of the generic descriptive relationship indicating a metadata relationship between fedora objects.  The subject is a fedora object and the predicate is a fedora object that represents metadata about the subject. ).freeze,
               label: "Has Metadata".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasDescription".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMetadataFor).freeze,
               type: "rdf:Property".freeze
      property :hasPart,
               label: "Has Part".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isPartOf).freeze,
               type: "rdf:Property".freeze
      property :hasSubset,
               label: "Has Subset".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasMember".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isSubsetOf).freeze,
               type: "rdf:Property".freeze
      property :isAnnotationOf,
               comment: %(A refinement of the generic descriptive relationship indicating a commentary relationship between fedora objects.  The subject is a fedora object that represents an annotation or comment and the predicate is a fedora object that is being commented upon by the subject.).freeze,
               label: "Is Annotation Of".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isDescriptionOf".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasAnnotation).freeze,
               type: "rdf:Property".freeze
      property :isConstituentOf,
               label: "Is Constituent Of".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isPartOf".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasConstituent).freeze,
               type: "rdf:Property".freeze
      property :isDependentOf,
               label: "Is Dependent Of".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDependent).freeze,
               type: "rdf:Property".freeze
      property :isDerivationOf,
               label: "Is Derivation Of".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDerivation).freeze,
               type: "rdf:Property".freeze
      property :isDescriptionOf,
               comment: %(A generic descriptive relationship between fedora objects.  The subject is a fedora object that represents a descriptive entity and the predicate is a fedora object that is being described in some manner by the subject.).freeze,
               label: "Is Description Of".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDescription).freeze,
               type: "rdf:Property".freeze
      property :isMemberOf,
               label: "Is Member Of".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isPartOf".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasMember).freeze,
               type: "rdf:Property".freeze
      property :isMemberOfCollection,
               label: "Is Member Of Collection".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMemberOf".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasCollectionMember).freeze,
               type: "rdf:Property".freeze
      property :isMetadataFor,
               comment: %(A refinement of the generic descriptive relationship indicating a metadata relationship between fedora objects.  The subject is a fedora object that represents metadata and the predicate is a fedora object for which the subject serves as metadata.).freeze,
               label: "Is Metadata For".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isDescriptionOf".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasMetadata).freeze,
               type: "rdf:Property".freeze
      property :isPartOf,
               label: "Is Part Of".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasPart).freeze,
               type: "rdf:Property".freeze
      property :isSubsetOf,
               label: "Is Subset Of".freeze,
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMemberOf".freeze,
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasSubset).freeze,
               type: "rdf:Property".freeze
    end
    class View < ::RDF::StrictVocabulary("info:fedora/fedora-system:def/view#")
      property :disseminates,
               comment: %(A property used to indicate that an object contains a datastream).freeze,
               label: "disseminates".freeze,
               domain: "info:fedora/fedora-system:FedoraObject-3.0".freeze,
               range: "info:fedora/fedora-system:def/model#Datastream".freeze,
               type: "rdf:Property".freeze
      property :disseminationType,
               comment: %(A property whose object is common to all Datastreams of a given DSID).freeze,
               label: "dissemination type".freeze,
               type: "rdf:Property".freeze
      property :isVolatile,
               comment: %(A property indicating that a datastream's content is a reference to content external to the repository).freeze,
               label: "isVolatile".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream".freeze,
               range: "xsd:boolean".freeze,
               type: "rdf:Property".freeze
      property :lastModifiedDate,
               comment: %(UTC datetime of the last change to an object or most recent version of this datastream).freeze,
               label: "lastModifiedDate".freeze,
               domain: ["info:fedora/fedora-system:def/model#FedoraObject".freeze, "info:fedora/fedora-system:def/model#Datastream".freeze],
               range: "xsd:dateTimeStamp".freeze,
               type: "rdf:Property".freeze
      property :mimeType,
               comment: %(The MIME type of this datastream's content).freeze,
               label: "mimeType".freeze,
               domain: "info:fedora/fedora-system:def/model#Datastream".freeze,
               range: "xsd:string".freeze,
               type: "rdf:Property".freeze
      property :version,
               comment: %(indicates Fedora server version in messaging).freeze,
               label: "Server version".freeze,
               type: "rdf:Property".freeze
    end
  end
end
