module ActiveFedora::Associations
  class RecordProxyFinder
    attr_reader :container
    delegate :contained_ids, to: :container
    def initialize(container:)
      @container = container
    end

    def call(record)
      record.reload # Reload to get new incoming relations.
      proxy_ids(record) & contained_ids
    end

    private

    def proxy_ids(record)
      relation_subjects(record)
    end

    def relation_subjects(record)
      record.resource.query(object: record.rdf_subject).subjects.to_a
    end
  end
end
