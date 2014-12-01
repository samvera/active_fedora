module ActiveFedora
  module QueryResultBuilder
    def self.lazy_reify_solr_results(solr_results, opts = {})
      Enumerator.new do |yielder|
        solr_results.each do |hit|
          yielder.yield(reify_solr_result(hit, opts))
        end
      end
    end

    def self.reify_solr_results(solr_results, opts = {})
      solr_results.collect { |hit| reify_solr_result(hit, opts) }
    end

    def self.reify_solr_result(hit, opts = {})
      klass = class_from_solr_document(hit)
      klass.find(hit[SOLR_DOCUMENT_ID], cast: true)
    end

    #Returns all possible classes for the solr object
    def self.classes_from_solr_document(hit, opts = {})
      classes = []

      hit[HAS_MODEL_SOLR_FIELD].each { |value| classes << Model.from_class_uri(value) }

      classes.compact
    end

    #Returns the best singular class for the solr object
    def self.class_from_solr_document(hit, opts = {})
      #Set the default starting point to the class specified, if available.
      best_model_match = Model.from_class_uri(opts[:class]) unless opts[:class].nil?
      Array(hit[HAS_MODEL_SOLR_FIELD]).each do |value|

        model_value = Model.from_class_uri(value)

        if model_value

          # Set as the first model in case opts[:class] was nil
          best_model_match ||= model_value

          # If there is an inheritance structure, use the most specific case.
          if best_model_match > model_value
            best_model_match = model_value
          end
        end
      end

      ActiveFedora::Base.logger.warn "Could not find a model for #{hit["id"]}, defaulting to ActiveFedora::Base" unless best_model_match if ActiveFedora::Base.logger
      best_model_match || ActiveFedora::Base
    end

    HAS_MODEL_SOLR_FIELD = SolrQueryBuilder.solr_name("has_model", :symbol).freeze

  end
end
