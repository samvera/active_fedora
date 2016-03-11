module ActiveFedora
  module QueryResultBuilder
    def self.lazy_reify_solr_results(solr_results, opts = {})
      return to_enum(:lazy_reify_solr_results, solr_results, opts) unless block_given?

      solr_results.each do |hit|
        yield reify_solr_result(hit, opts)
      end
    end

    def self.reify_solr_results(solr_results, opts = {})
      lazy_reify_solr_results(solr_results, opts).to_a
    end

    def self.reify_solr_result(hit, _opts = {})
      klass = class_from_solr_document(hit)
      klass.find(hit[SOLR_DOCUMENT_ID], cast: true)
    end

    # Returns all possible classes for the solr object
    def self.classes_from_solr_document(hit, _opts = {})
      ActiveFedora.model_mapper.classifier(hit).models
    end

    # Returns the best singular class for the solr object
    def self.class_from_solr_document(hit, opts = {})
      best_model_match = ActiveFedora.model_mapper.classifier(hit).best_model(opts)
      ActiveFedora::Base.logger.warn "Could not find a model for #{hit['id']}, defaulting to ActiveFedora::Base" if ActiveFedora::Base.logger && best_model_match == ActiveFedora::Base
      best_model_match
    end

    HAS_MODEL_SOLR_FIELD = SolrQueryBuilder.solr_name("has_model", :symbol).freeze
  end
end
