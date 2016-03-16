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
      self.solr_doc = solr_doc
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
        active_fedora_class.allocate.init_with_json(profile_json) do |allocated_object|
          create_key = allocated_object.indexing_service.class.create_time_solr_name
          modified_key = allocated_object.indexing_service.class.modified_time_solr_name
          allocated_object.resource.set_value(:create_date, DateTime.parse(solr_doc[create_key])) if solr_doc[create_key]
          allocated_object.resource.set_value(:modified_date, DateTime.parse(solr_doc[modified_key])) if solr_doc[modified_key]
        end
      end

      def solr_doc
        @solr_doc ||= begin
          self.solr_doc = context.search_by_id(id)
        end
      end

      def solr_doc=(solr_doc)
        validate_solr_doc_and_id!(@solr_doc) unless @solr_doc.nil?
        @solr_doc = solr_doc
      end

      def validate_solr_doc_and_id!(document)
        solr_id = document[ActiveFedora.id_field]
        return if id == solr_id
        raise ActiveFedora::FedoraSolrMismatchError, id, solr_id
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
