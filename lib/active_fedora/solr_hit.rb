module ActiveFedora
  class SolrHit < Delegator
    def self.for(hit)
      return hit if hit.is_a? ActiveFedora::SolrHit

      SolrHit.new(hit)
    end

    delegate :models, to: :classifier

    def __getobj__
      @document # return object we are delegating to, required
    end

    alias static_config __getobj__

    def __setobj__(obj)
      @document = obj
    end

    attr_reader :document

    def initialize(document)
      document = document.with_indifferent_access
      super
      @document = document
    end

    def id
      document[ActiveFedora.id_field]
    end

    def rdf_uri
      ::RDF::URI.new(ActiveFedora::Base.id_to_uri(id))
    end

    def model(opts = {})
      best_model_match = classifier.best_model(opts)
      ActiveFedora::Base.logger.warn "Could not find a model for #{id}, defaulting to ActiveFedora::Base" if best_model_match == ActiveFedora::Base
      best_model_match
    end

    def model?(model_to_check)
      models.any? do |model|
        model_to_check >= model
      end
    end

    def reify(opts = {})
      model(opts).find(id, cast: true)
    end

    private

      def classifier
        ActiveFedora.model_mapper.classifier(document)
      end
  end
end
