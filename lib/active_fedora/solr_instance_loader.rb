module ActiveFedora
  class FedoraSolrMismatchError < ActiveFedora::ObjectNotFoundError
    def initialize(fedora_id, solr_document_id)
      super("Solr ID and Fedora ID do not match; Solr ID=#{solr_document_id}, Fedora ID=#{fedora_id}")
    end
  end

  # Responsible for loading an ActiveFedora::Base proxy from a Solr document.
  class SolrInstanceLoader
    attr_reader :context, :id
    private :context, :id
    def initialize(context, id, solr_doc = nil)
      @context = context
      @id = id
      @solr_doc = solr_doc
      validate_solr_doc_and_id!(@solr_doc)
    end

    def object
      return @object if @object
      @object = allocate_object
      @object.readonly!
      @object.freeze
      @object
    end

    private

    def allocate_object
      active_fedora_class.allocate.init_with_json(profile_json)
    end

    def solr_doc
      @solr_doc ||= begin
        result = context.find_with_conditions(id: id)
        if result.empty?
          raise ActiveFedora::ObjectNotFoundError, "Object #{id} not found in solr"
        end
        @solr_doc = result.first
        validate_solr_doc_and_id!(@solr_doc)
        @solr_doc
      end
    end

    def validate_solr_doc_and_id!(document)
      return true if document.nil?
      solr_id = document[SOLR_DOCUMENT_ID]
      if id != solr_id
        raise ActiveFedora::FedoraSolrMismatchError.new(id, solr_id)
      end
    end

    def active_fedora_class
      @active_fedora_class ||= ActiveFedora::QueryResultBuilder.class_from_solr_document(solr_doc)
    end

    def profile_json
      @profile_json ||= begin
        profile_json = Array(solr_doc[ActiveFedora::IndexingService.profile_solr_name]).first
        unless profile_json.present?
          raise ActiveFedora::ObjectNotFoundError, "Object #{id} does not contain a solrized profile"
        end
        profile_json
      end
    end
  end
end
