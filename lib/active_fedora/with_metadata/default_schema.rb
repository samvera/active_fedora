# frozen_string_literal: true
# These are the default properties defined on a resource that has WithMetadata
# added to it. This is most commonly used with ActiveFedora::File, when we want
# to add rdf triples to a non-rdf resource and have them persisted.
module ActiveFedora::WithMetadata
  class DefaultSchema < ActiveTriples::Schema
    def self.legacy_ebucore_vocabulary
      @legacy_ebucore_vocabulary ||= Class.new(RDF::StrictVocabulary("http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#")) do
        property :filename,
          comment: %(The name of the file containing the Resource.),
          domain: "ebucore:Resource",
          label: "File name",
          range: "xsd:string",
          type: "rdf:Property"
      end
    end

    property :label, predicate: ::RDF::RDFS.label
    property :file_name, predicate: legacy_ebucore_vocabulary.filename
    property :file_size, predicate: ::RDF::Vocab::EBUCore.fileSize
    property :date_created, predicate: ::RDF::Vocab::EBUCore.dateCreated
    property :date_modified, predicate: ::RDF::Vocab::EBUCore.dateModified
    property :byte_order, predicate: SweetJPLTerms.byteOrder
    # This is a server-managed predicate which means Fedora does not let us change it.
    property :file_hash, predicate: ::RDF::Vocab::PREMIS.hasMessageDigest, server_managed: true
  end
end
