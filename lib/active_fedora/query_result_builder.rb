module ActiveFedora
  module QueryResultBuilder
    def self.lazy_reify_solr_results(solr_results, opts = {})
      return to_enum(:lazy_reify_solr_results, solr_results, opts) unless block_given?

      solr_results.each do |hit|
        yield ActiveFedora::SolrHit.for(hit).reify(opts)
      end
    end

    def self.reify_solr_results(solr_results, opts = {})
      lazy_reify_solr_results(solr_results, opts).to_a
    end

    def self.reify_solr_result(hit, _opts = {})
      Deprecation.warn(ActiveFedora::Base, 'ActiveFedora::QueryResultBuilder.reify_solr_result is deprecated and will be removed in ActiveFedora 10.0; call #reify on the SolrHit instead.')
      ActiveFedora::SolrHit.for(hit).reify
    end

    # Returns all possible classes for the solr object
    def self.classes_from_solr_document(hit, _opts = {})
      Deprecation.warn(ActiveFedora::Base, 'ActiveFedora::QueryResultBuilder.classes_from_solr_document is deprecated and will be removed in ActiveFedora 10.0; call #models on the SolrHit instead.')
      ActiveFedora::SolrHit.for(hit).models
    end

    # Returns the best singular class for the solr object
    def self.class_from_solr_document(hit, opts = {})
      Deprecation.warn(ActiveFedora::Base, 'ActiveFedora::QueryResultBuilder.class_from_solr_document is deprecated and will be removed in ActiveFedora 10.0; call #model on the SolrHit instead.')
      ActiveFedora::SolrHit.for(hit).model(opts)
    end

    HAS_MODEL_SOLR_FIELD = ActiveFedora.index_field_mapper.solr_name("has_model", :symbol).freeze
  end
end
