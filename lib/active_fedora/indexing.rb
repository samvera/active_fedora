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
      autoload :DescendantFetcher
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

        # @param [Integer] batch_size - The number of Fedora objects to process for each SolrService.add call. Default 50.
        # @param [Boolean] softCommit - Do we perform a softCommit when we add the to_solr objects to SolrService. Default true.
        # @param [Boolean] progress_bar - If true output progress bar information. Default false.
        # @param [Boolean] final_commit - If true perform a hard commit to the Solr service at the completion of the batch of updates. Default false.
        def reindex_everything(batch_size: 50, softCommit: true, progress_bar: false, final_commit: false)
          # skip root url
          descendants = descendant_uris(ActiveFedora.fedora.base_uri, exclude_uri: true)

          batch = []

          progress_bar_controller = ProgressBar.create(total: descendants.count, format: "%t: |%B| %p%% %e") if progress_bar

          descendants.each do |uri|
            logger.debug "Re-index everything ... #{uri}"

            batch << ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri)).to_solr

            if (batch.count % batch_size).zero?
              SolrService.add(batch, softCommit: softCommit)
              batch.clear
            end

            progress_bar_controller.increment if progress_bar_controller
          end

          if batch.present?
            SolrService.add(batch, softCommit: softCommit)
            batch.clear
          end

          if final_commit
            logger.debug "Solr hard commit..."
            SolrService.commit
          end
        end

        def descendant_uris(uri, exclude_uri: false)
          DescendantFetcher.new(uri, exclude_self: exclude_uri).descendant_and_self_uris
        end
      end
  end
end
