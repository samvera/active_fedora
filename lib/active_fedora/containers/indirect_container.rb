module ActiveFedora
  class IndirectContainer < Container
    type ::RDF::Vocab::LDP.IndirectContainer

    property :inserted_content_relation, predicate: ::RDF::Vocab::LDP.insertedContentRelation
  end
end
