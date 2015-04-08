module ActiveFedora
  module Indexing
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Map
    end

    # Return a Hash representation of this object where keys in the hash are appropriate Solr field names.
    # @param [Hash] solr_doc (optional) Hash to insert the fields into
    # @param [Hash] opts (optional)
    # If opts[:model_only] == true, the base object metadata and the RELS-EXT datastream will be omitted.  This is mainly to support shelver, which calls .to_solr for each model an object subscribes to.
    def to_solr(solr_doc = Hash.new, opts={})
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
        ENABLE_SOLR_UPDATES
      end

      # Determines whether an update operation causes a solr index of this object by default.
      # Override this if you need different behavior
      def update_needs_index?
        ENABLE_SOLR_UPDATES
      end

    private

      # index the record after it has been persisted to Fedora
      def create_record(options = {})
        super
        update_index if create_needs_index? && options.fetch(:update_index, true)
        true
      end

      # index the record after it has been updated in Fedora
      def update_record(options = {})
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

      def indexer
        IndexingService
      end

      def reindex_everything
        descendants = descendant_uris(ActiveFedora::Base.id_to_uri(''))
        descendants.shift # Discard the root uri
        descendants.each do |uri|
          logger.debug "Re-index everything ... #{uri}"
          ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri)).update_index
        end
      end

      # This method can be used instead of ActiveFedora::Model::ClassMethods.find.
      # It works similarly except it populates an object from Solr instead of Fedora.
      # It is most useful for objects used in read-only displays in order to speed up loading time.  If only
      # a id is passed in it will query solr for a corresponding solr document and then use it
      # to populate this object.
      #
      # If a value is passed in for optional parameter solr_doc it will not query solr again and just use the
      # one passed to populate the object.
      #
      # It will anything stored within solr such as metadata and relationships.  Non-metadata attached files will not
      # be loaded and if needed you should use find instead.
      def load_instance_from_solr(id, solr_doc=nil)
        SolrInstanceLoader.new(self, id, solr_doc).object
      end

      def descendant_uris(uri)
        resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
        # GET could be slow if it's a big resource, we're using HEAD to avoid this problem,
        # but this causes more requests to Fedora.
        return [] unless Ldp::Response.rdf_source?(resource.head)
        immediate_descendant_uris = resource.graph.query(predicate: ::RDF::LDP.contains).map { |descendant| descendant.object.to_s }
        all_descendants_uris = [uri]
        immediate_descendant_uris.each do |descendant_uri|
          all_descendants_uris += descendant_uris(descendant_uri)
        end
        all_descendants_uris
      end

    end

  end
end
