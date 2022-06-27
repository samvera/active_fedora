# -*- encoding: utf-8 -*-
# frozen_string_literal: true
# This file generated automatically using vocab-fetch from github.com:fcrepo3/fcrepo/master/fcrepo-server/src/main/resources/rdfs/fedora_relsext_ontology.rdfs
# and edited for clarity and additional terms published in different serializations of the voabularies
require 'rdf'
module ActiveFedora::RDF
  module Fcrepo
    class System < ::RDF::StrictVocabulary("info:fedora/fedora-system:")
      term :"ContentModel-3.0",
           comment: %(Base Fedora 3 CModel cModel),
           label: "Fedora 3 Content Model",
           subClassOf: "info:fedora/fedora-system:def/model#FedoraObject",
           type: "info:fedora/fedora-system:def/model#FedoraObject"
      term :"FedoraObject-3.0",
           comment: %(Base Fedora 3 Object cModel),
           label: "Fedora 3 Object",
           subClassOf: "info:fedora/fedora-system:def/model#FedoraObject",
           type: "info:fedora/fedora-system:def/model#FedoraObject"
      term :"ServiceDefinition-3.0",
           comment: %(Fedora 3 Service Definition/BDef cModel),
           label: "Fedora 3 Service Definition",
           subClassOf: "info:fedora/fedora-system:def/model#FedoraObject",
           type: "info:fedora/fedora-system:def/model#FedoraObject"
      term :"ServiceDeployment-3.0",
           comment: %(Fedora 3 Service Deployment/BMech cModel),
           label: "Fedora 3 Service Deployment",
           subClassOf: "info:fedora/fedora-system:def/model#FedoraObject",
           type: "info:fedora/fedora-system:def/model#FedoraObject"
    end

    class Model < ::RDF::StrictVocabulary("info:fedora/fedora-system:def/model#")
      # Class definitions
      term :FedoraObject,
           comment: %(The base type of all objects in Fedora),
           label: "FedoraObject",
           subClassOf: "rdfs:Resource",
           type: "rdfs:Class"
      term :Datastream,
           comment: %(Binary data associated with a Fedora object),
           label: "Datastream",
           subClassOf: "rdfs:Resource",
           type: "rdfs:Class"
      term :ExtProperty,
           comment: %(Reification of an extension property of a Fedora object used in messaging),
           label: "ExtProperty",
           subClassOf: "rdf:Property",
           type: "rdfs:Class"
      term :State,
           comment: %(The state of a Fedora object or datastream),
           label: "State",
           subClassOf: "rdfs:Resource",
           type: "rdfs:Class"
      term :Active,
           comment: %(State of an object available in the repository),
           label: "Active",
           subClassOf: "rdfs:Resource",
           type: "info:fedora/fedora-system:def/model#State"
      term :Deleted,
           comment: %(State of an object that should be considered deleted, but is not purged),
           label: "Deleted",
           subClassOf: "rdfs:Resource",
           type: "info:fedora/fedora-system:def/model#State"
      term :Inactive,
           comment: %(State of an object that should be considered temporarily unavailable),
           label: "Inactive",
           subClassOf: "rdfs:Resource",
           type: "info:fedora/fedora-system:def/model#State"
      # Property definitions
      property :altIds,
               comment: %(The alternate IDs for a datastream),
               label: "Alternate IDs",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string",
               type: "rdf:Property"
      property :controlGroup,
               comment: %(indicates whether a Datastream's content is inline XML (X), Managed (M), Referenced (R) or External (E)),
               label: "controlGroup",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string",
               type: "rdf:Property"
      property :createdDate,
               comment: %(The UTC datetime an object was created),
               label: "createdDate",
               domain: "info:fedora/fedora-system:def/model#FedoraObject",
               range: "xsd:dateTimeStamp",
               type: "rdf:Property"
      property :definesMethod,
               comment: %(indicates the name of a service method defined in this interface),
               label: "definesMethod",
               domain: "info:fedora/fedora-system:ServiceDefinition-3.0",
               range: "xsd:NCName",
               type: "rdf:Property"
      property :digest,
               comment: %(indicates the checksum digest of a datastream's contents or the keyword 'none'),
               label: "digest",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string",
               type: "rdf:Property"
      property :digestType,
               comment: %(indicates either the checksum algorithm or the keyword DISABLED),
               label: "digestType",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string",
               type: "rdf:Property"
      property :downloadFilename,
               comment: %(indicates the name to be used when downloading a datastream's contents),
               label: "downloadFilename",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string",
               type: "rdf:Property"
      property :extProperty,
               comment: %(indicates an extension property of an object in Fedora in messaging),
               label: "extProperty",
               domain: "info:fedora/fedora-system:def/model#FedoraObject",
               range: "info:fedora/fedora-system:def/model#ExtProperty",
               type: "rdf:Property"
      property :formatURI,
               comment: %(A URI indicating the format of a datastream's content),
               label: "formatURI",
               type: "rdf:Property"
      property :hasModel,
               comment: %(Indicates the Fedora 3 CModels for this object),
               label: "hasModel",
               subPropertyOf: "rdf:type",
               domain: "info:fedora/fedora-system:FedoraObject-3.0",
               range: "info:fedora/fedora-system:ContentModel-3.0",
               type: "rdf:Property"
      property :hasService,
               comment: %(indicates the Fedora 3 Service Definitions applicable to this CModel),
               label: "hasService",
               domain: "info:fedora/fedora-system:ContentModel-3.0",
               range: "info:fedora/fedora-system:ServiceDefinition-3.0",
               type: "rdf:Property"
      property :isContractorOf,
               comment: %(indicates the Fedora 3 Content Models this deployment applies to),
               label: "",
               domain: "info:fedora/fedora-system:ServiceDeployment-3.0",
               range: "info:fedora/fedora-system:ContentModel-3.0",
               type: "rdf:Property"
      property :isDeploymentOf,
               comment: %(indicates the Fedora 3 Service Definitions this deployment implements),
               label: "isDeploymentOf",
               domain: "info:fedora/fedora-system:ServiceDeployment-3.0",
               range: "info:fedora/fedora-system:ServiceDefinition-3.0",
               type: "rdf:Property"
      property :label,
               comment: %(The label applied to a Fedora object),
               label: "label",
               domain: "info:fedora/fedora-system:def/model#FedoraObject",
               range: "xsd:string",
               type: "rdf:Property"
      property :length,
               comment: %(indicates the length of a datastream's contents),
               label: "length",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:nonNegativeInteger",
               type: "rdf:Property"
      property :ownerId,
               comment: %(indicates the owner of an object),
               label: "ownerId",
               type: "rdf:Property"
      property :PID,
               comment: %(the Fedora 3 PID for an object),
               label: "PID",
               domain: "info:fedora/fedora-system:def/model#FedoraObject",
               range: "xsd:string",
               type: "rdf:Property"
      property :state,
               comment: %(indicates the state of the object or datastream),
               label: "state",
               domain: ["info:fedora/fedora-system:def/model#FedoraObject", "info:fedora/fedora-system:def/model#Datastream"],
               range: "info:fedora/fedora-system:def/model#State",
               type: "rdf:Property"
      property :versionable,
               comment: %(indicates whether a datastream's property and contents changes are being tracked as versions),
               label: "versionable",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:boolean",
               type: "rdf:Property"
    end

    class RelsExt < ::RDF::StrictVocabulary("info:fedora/fedora-system:def/relations-external#")
      # Property definitions
      property :fedoraRelationship,
               comment: %(The primitive property for all object-to-object relationships in the fedora ontology),
               label: "Fedora Relationship",
               type: "rdf:Property"
      property :hasAnnotation,
               comment: %(A refinement of the generic descriptive relationship indicating a commentary relationship between fedora objects.  The subject is a fedora object that is being commented on and the predicate is a fedora object that represents an annotation or comment about the subject. ),
               label: "Has Annotation",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasDescription",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isAnnotationOf),
               type: "rdf:Property"
      property :hasCollectionMember,
               label: "Has Collection Member",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasMember",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMemberOfCollection),
               type: "rdf:Property"
      property :hasConstituent,
               label: "Has Constituent",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasPart",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isConstituentOf),
               type: "rdf:Property"
      property :hasDependent,
               label: "Has Dependent",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDependentOf),
               type: "rdf:Property"
      property :hasDerivation,
               label: "Has Derivation",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDerivationOf),
               type: "rdf:Property"
      property :hasDescription,
               comment: %(A generic descriptive relationship between fedora objects.  The subject is a fedora object that is being described in some manner and the predicate is a fedora object that represents a descriptive entity that is about the subject. ),
               label: "Has Description",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDescriptionOf),
               type: "rdf:Property"
      property :hasEquivalent,
               label: "Has Equivalent",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               type: "rdf:Property"
      property :hasMember,
               label: "Has Member",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasPart/",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMemberOf),
               type: "rdf:Property"
      property :hasMetadata,
               comment: %(A refinement of the generic descriptive relationship indicating a metadata relationship between fedora objects.  The subject is a fedora object and the predicate is a fedora object that represents metadata about the subject. ),
               label: "Has Metadata",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasDescription",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMetadataFor),
               type: "rdf:Property"
      property :hasPart,
               label: "Has Part",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isPartOf),
               type: "rdf:Property"
      property :hasSubset,
               label: "Has Subset",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasMember",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isSubsetOf),
               type: "rdf:Property"
      property :isAnnotationOf,
               comment: %(A refinement of the generic descriptive relationship indicating a commentary relationship between fedora objects.  The subject is a fedora object that represents an annotation or comment and the predicate is a fedora object that is being commented upon by the subject.),
               label: "Is Annotation Of",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isDescriptionOf",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasAnnotation),
               type: "rdf:Property"
      property :isConstituentOf,
               label: "Is Constituent Of",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isPartOf",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasConstituent),
               type: "rdf:Property"
      property :isDependentOf,
               label: "Is Dependent Of",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDependent),
               type: "rdf:Property"
      property :isDerivationOf,
               label: "Is Derivation Of",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDerivation),
               type: "rdf:Property"
      property :isDescriptionOf,
               comment: %(A generic descriptive relationship between fedora objects.  The subject is a fedora object that represents a descriptive entity and the predicate is a fedora object that is being described in some manner by the subject.),
               label: "Is Description Of",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDescription),
               type: "rdf:Property"
      property :isMemberOf,
               label: "Is Member Of",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isPartOf",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasMember),
               type: "rdf:Property"
      property :isMemberOfCollection,
               label: "Is Member Of Collection",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMemberOf",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasCollectionMember),
               type: "rdf:Property"
      property :isMetadataFor,
               comment: %(A refinement of the generic descriptive relationship indicating a metadata relationship between fedora objects.  The subject is a fedora object that represents metadata and the predicate is a fedora object for which the subject serves as metadata.),
               label: "Is Metadata For",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isDescriptionOf",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasMetadata),
               type: "rdf:Property"
      property :isPartOf,
               label: "Is Part Of",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasPart),
               type: "rdf:Property"
      property :isSubsetOf,
               label: "Is Subset Of",
               subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMemberOf",
               "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasSubset),
               type: "rdf:Property"
    end

    class View < ::RDF::StrictVocabulary("info:fedora/fedora-system:def/view#")
      property :disseminates,
               comment: %(A property used to indicate that an object contains a datastream),
               label: "disseminates",
               domain: "info:fedora/fedora-system:FedoraObject-3.0",
               range: "info:fedora/fedora-system:def/model#Datastream",
               type: "rdf:Property"
      property :disseminationType,
               comment: %(A property whose object is common to all Datastreams of a given DSID),
               label: "dissemination type",
               type: "rdf:Property"
      property :isVolatile,
               comment: %(A property indicating that a datastream's content is a reference to content external to the repository),
               label: "isVolatile",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:boolean",
               type: "rdf:Property"
      property :lastModifiedDate,
               comment: %(UTC datetime of the last change to an object or most recent version of this datastream),
               label: "lastModifiedDate",
               domain: ["info:fedora/fedora-system:def/model#FedoraObject", "info:fedora/fedora-system:def/model#Datastream"],
               range: "xsd:dateTimeStamp",
               type: "rdf:Property"
      property :mimeType,
               comment: %(The MIME type of this datastream's content),
               label: "mimeType",
               domain: "info:fedora/fedora-system:def/model#Datastream",
               range: "xsd:string",
               type: "rdf:Property"
      property :version,
               comment: %(indicates Fedora server version in messaging),
               label: "Server version",
               type: "rdf:Property"
    end
  end
end
