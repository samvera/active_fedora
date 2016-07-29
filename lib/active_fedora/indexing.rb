module ActiveFedora
  # Mix in this module to update Solr on save.
  # Assign a new indexer at the class level where this is mixed in
  #   (or define an #indexing_service method)
  #   to change the document contents sent to solr
  #
  # Example indexing services are:
  # @see ActiveFedora::IndexingService
  # @see ActiveFedora::RDF::IndexingService
  module Indexing
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Map
    end

    included do
      # Because the previous method of setting indexer was to override
      # the class method, we must ensure that we aren't using the instance
      # reader so that the old method still works.
      class_attribute :indexer, instance_accessor: false

      # This is the default indexer class to use for this model.
      self.indexer = IndexingService
    end

    # Return a Hash representation of this object where keys in the hash are appropriate Solr field names.
    # @param [Hash] _solr_doc (optional) Hash to insert the fields into
    # @param [Hash] _opts (optional)
    # If opts[:model_only] == true, the base object metadata and the RELS-EXT datastream will be omitted.  This is mainly to support shelver, which calls #to_solr for each model an object subscribes to.
    def to_solr(_solr_doc = {}, _opts = {})
      indexing_service.generate_solr_document
    end

    def indexing_service
      @indexing_service ||= self.class.indexer.new(self)
    end

    # Updates Solr index with self.
    def update_index
      SolrService.add(to_solr, softCommit: true)
    end

    protected

      # Determines whether a create operation causes a solr index of this object by default.
      # Override this if you need different behavior.
      def create_needs_index?
        ActiveFedora.enable_solr_updates?
      end

      # Determines whether an update operation causes a solr index of this object by default.
      # Override this if you need different behavior
      def update_needs_index?
        ActiveFedora.enable_solr_updates?
      end

    private

      # index the record after it has been persisted to Fedora
      def _create_record(options = {})
        super
        update_index if create_needs_index? && options.fetch(:update_index, true)
        true
      end

      # index the record after it has been updated in Fedora
      def _update_record(options = {})
        super
        update_index if update_needs_index? && options.fetch(:update_index, true)
        true
      end

      module ClassMethods
        # @return ActiveFedora::Indexing::Map
        def index_config
          @index_config ||= if superclass.respond_to?(:index_config)
                              superclass.index_config.deep_dup
                            else
                              ActiveFedora::Indexing::Map.new
                            end
        end

        def reindex_everything
          descendants = descendant_uris(ActiveFedora::Base.id_to_uri(''))
          descendants.shift # Discard the root uri
          descendants.each do |uri|
            logger.debug "Re-index everything ... #{uri}"
            ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri)).update_index
          end
        end

        def descendant_uris(uri)
          resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
          # GET could be slow if it's a big resource, we're using HEAD to avoid this problem,
          # but this causes more requests to Fedora.
          return [] unless resource.head.rdf_source?
          immediate_descendant_uris = resource.graph.query(predicate: ::RDF::Vocab::LDP.contains).map { |descendant| descendant.object.to_s }
          all_descendants_uris = [uri]
          immediate_descendant_uris.each do |descendant_uri|
            all_descendants_uris += descendant_uris(descendant_uri)
          end
          all_descendants_uris
        end
      end
  end
end
