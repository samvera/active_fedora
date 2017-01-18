module ActiveFedora::Associations
  ##
  # Finds the objects which associate with a given record and are contained
  # within the given container. Uses #repository to find the objects.
  class ContainedFinder
    attr_reader :container, :repository, :proxy_class
    delegate :contained_ids, to: :container
    # @param [#contained_ids] container a container that records are stored
    #   under.
    # @param [#translate_uri_to_id, #find] repository a repository to build
    #   objects from.
    # @param [ActiveFedora::Base] proxy_class class that represents an
    #   ore:Proxy
    def initialize(container:, repository:, proxy_class:)
      @container = container
      @repository = repository
      @proxy_class = proxy_class
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
        IDComposite.new(proxy_ids(record) & contained_ids.to_a, repository.translate_uri_to_id)
      end

      def proxy_ids(record)
        relation_subjects(record)
      end

      # This could be done with Prefer InboundReferences, but that is
      # a slow fedora call
      def relation_subjects(record)
        query = ActiveFedora::SolrQueryBuilder.construct_query_for_rel(
          [[:has_model, proxy_class.to_rdf_representation], [:proxyFor, record.id]]
        )
        rows = ActiveFedora::SolrService::MAX_ROWS
        ActiveFedora::SolrService.query(query, fl: 'id', rows: rows).map(&:rdf_uri)
      end
  end
end
