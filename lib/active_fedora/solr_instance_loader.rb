module ActiveFedora
  class FedoraSolrMismatchError < ActiveFedora::ObjectNotFoundError
    def initialize(pid, solr_document_id)
      super("Solr record id and pid do not match; Solr ID=#{solr_document_id}, PID=#{pid}")
    end
  end

  # Responsible for loading an ActiveFedora::Base proxy from a Solr document.
  class SolrInstanceLoader
    attr_reader :context, :pid
    private :context, :pid
    def initialize(context, pid, solr_doc = nil)
      @context = context
      @pid = pid
      @solr_doc = solr_doc
      validate_solr_doc_and_pid!(@solr_doc)
    end

    def object
      return @object if @object
      @object = allocate_object
      @object.rels_ext
      load_object_datastreams(@object)
      @object.inner_object.freeze
      @object
    end

    private

    def allocate_object
      active_fedora_class.allocate.init_with(solr_digital_object)
    end

    def solr_digital_object
      SolrDigitalObject.new(solr_doc, profile_hash, active_fedora_class)
    end


    def load_object_datastreams(obj)
      obj.datastreams.each_value do |ds|
        if ds.respond_to?(:profile_from_hash) and (ds_prof = profile_hash['datastreams'][ds.dsid])
          ds.profile_from_hash(ds_prof)
        end
        ds.from_solr(solr_doc) if ds.respond_to?(:from_solr)
      end
    end

    def solr_doc
      @solr_doc ||= begin
        result = context.find_with_conditions(:id=>pid)
        if result.empty?
          raise ActiveFedora::ObjectNotFoundError, "Object #{pid} not found in solr"
        end
        @solr_doc = result.first
        validate_solr_doc_and_pid!(@solr_doc)
        @solr_doc
      end
    end

    def validate_solr_doc_and_pid!(document)
      return true if document.nil?
      solr_id = document[SOLR_DOCUMENT_ID]
      if pid != solr_id
        raise ActiveFedora::FedoraSolrMismatchError.new(pid, solr_id)
      end
    end

    def active_fedora_class
      @active_fedora_class ||= ActiveFedora::SolrService.class_from_solr_document(solr_doc)
    end

    def profile_json
      @profile_json ||= begin
        profile_json = Array(solr_doc[ActiveFedora::Base.profile_solr_name]).first
        unless profile_json.present?
          raise ActiveFedora::ObjectNotFoundError, "Object #{pid} does not contain a solrized profile"
        end
        profile_json
      end
    end

    def profile_hash
      @profile_hash ||= ActiveSupport::JSON.decode(profile_json)
    end

  end
end
