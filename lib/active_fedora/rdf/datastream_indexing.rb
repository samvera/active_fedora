module ActiveFedora::RDF
  module DatastreamIndexing
    extend ActiveSupport::Concern

    def to_solr(solr_doc={}, opts={}) # :nodoc:
      super.tap do |solr_doc|
        solrize_rdf_assertions(opts[:name], solr_doc)
      end
    end

    # Gives the primary solr name for a column. If there is more than one indexer on the field definition, it gives the first
    def primary_solr_name(field, file_path)
      config = self.class.config_for_term_or_uri(field)
      return nil unless config # punt on index names for deep nodes!
      if behaviors = config.behaviors
        behaviors.each do |behavior|
          result = ActiveFedora::SolrQueryBuilder.solr_name(apply_prefix(field, file_path), behavior, type: config.type)
          return result if Solrizer::DefaultDescriptors.send(behavior).evaluate_suffix(:text).stored?
        end
        raise RuntimeError "no stored fields were found"
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
        lambda { |field_name| apply_prefix(field_name, file_path) }
      end

      def apply_prefix(name, file_path)
        prefix(file_path) + name.to_s
      end

  end
end

