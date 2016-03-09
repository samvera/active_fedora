module ActiveFedora
  # Create model classifiers for resources or solr documents
  class DefaultModelMapper
    attr_reader :classifier_class, :solr_field, :predicate

    def initialize(classifier_class: ActiveFedora::ModelClassifier, solr_field: ActiveFedora::QueryResultBuilder::HAS_MODEL_SOLR_FIELD, predicate: ActiveFedora::RDF::Fcrepo::Model.hasModel)
      @classifier_class = classifier_class
      @solr_field = solr_field
      @predicate = predicate
    end

    def classifier(resource)
      models = if resource.respond_to? :graph
                 resource.graph.query([nil, predicate, nil]).map { |rg| rg.object.to_s }
               elsif resource.respond_to? :[]
                 resource[solr_field] || []
               else
                 []
               end

      classifier_class.new(models)
    end
  end
end
