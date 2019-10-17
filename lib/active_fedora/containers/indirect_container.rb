module ActiveFedora
  class IndirectContainer < Container
    property :inserted_content_relation, predicate: ::RDF::Vocab::LDP.insertedContentRelation

    def build_ldp_resource(id)
      IndirectContainerResource.new(ActiveFedora.fedora.connection, self.class.id_to_uri(id))
    end
  end
end
