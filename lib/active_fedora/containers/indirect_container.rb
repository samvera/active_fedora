module ActiveFedora
  class IndirectContainer < Container
    property :inserted_content_relation, predicate: ::RDF::Vocab::LDP.insertedContentRelation
  end
end
