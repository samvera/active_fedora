module ActiveFedora::RDF
  module DatastreamIndexing
    extend ActiveSupport::Concern

    def to_solr(solr_doc = {}, opts = {}) # :nodoc:
      super.tap do |new_doc|
        solrize_rdf_assertions(opts[:name], new_doc)
      end
    end

    module ClassMethods
      def indexer
        ActiveFedora::RDF::IndexingService
      end

      def index_config
        @index_config ||= ActiveFedora::Indexing::Map.new
      end
    end

    protected

      def indexing_service
        @indexing_service ||= self.class.indexer.new(self)
      end

      # Serialize the datastream's RDF relationships to solr
      # @param [String] file_path used to prefix the keys in the solr document
      # @param [Hash] solr_doc @default an empty Hash
      def solrize_rdf_assertions(file_path, solr_doc = {})
        solr_doc.merge! indexing_service.generate_solr_document(prefix_method(file_path))
      end

      # Returns a function that takes field name and returns a solr document key
      def prefix_method(file_path)
        ->(field_name) { apply_prefix(field_name, file_path) }
      end

      def apply_prefix(name, file_path)
        prefix(file_path) + name.to_s
      end
  end
end
