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
      @object = solr_doc.instantiate_with_json
      @object.readonly!
      @object.freeze
      @object
    end

    private

      def solr_doc
        @solr_doc ||= begin
          self.solr_doc = context.search_by_id(id)
        end
      end

      def solr_doc=(solr_doc)
        unless solr_doc.nil?
          solr_doc = ActiveFedora::SolrHit.for(solr_doc)
          validate_solr_doc_and_id!(solr_doc)
          @solr_doc = solr_doc
        end
      end

      def validate_solr_doc_and_id!(document)
        return if id == document.id
        raise ActiveFedora::FedoraSolrMismatchError, id, document.id
      end
  end
end
