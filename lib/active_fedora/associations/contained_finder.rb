module ActiveFedora::Associations
  ## 
  # Finds the objects which associate with a given record and are contained
  # within the given container. Uses #repository to find the objects.
  class ContainedFinder
    attr_reader :container, :repository
    delegate :contained_ids, to: :container
    # @param [#contained_ids] container a container that records are stored
    #   under.
    # @param [#translate_uri_to_id, #find] repository a repository to build
    #   objects from.
    def initialize(container:, repository:)
      @container = container
      @repository = repository
    end

    # @param [ActiveFedora::Base] record a record which you want to find the
    #   reference node for.
    # @return [Array<ActiveFedora::Base>] This returns whatever type
    #   repository.find returns.
    def find(record)
      record.reload
      repository.find(matching_ids(record))
    end

    private

    def matching_ids(record)
      IDComposite.new(proxy_ids(record) & contained_ids, repository.translate_uri_to_id)
    end

    def proxy_ids(record)
      relation_subjects(record)
    end

    def relation_subjects(record)
      record.resource.query(object: record.rdf_subject).subjects.to_a
    end
  end

end
