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

    HAS_MODEL_SOLR_FIELD = ActiveFedora.index_field_mapper.solr_name("has_model", :symbol).freeze
  end
end
