module ActiveFedora
  class IndexingService
    attr_reader :object

    # @param [#create_date, #modified_date, #has_model, #id, #to_json, #attached_files, #[]] obj
    # The class of obj must respond to these methods:
    #   inspect
    #   outgoing_reflections
    def initialize(obj)
      @object = obj
    end

    def self.profile_solr_name
      @profile_solr_name ||= ActiveFedora::SolrQueryBuilder.solr_name("object_profile", :displayable)
    end

    def profile_service
      ProfileIndexingService
    end

    def rdf_service
      RDF::IndexingService
    end

    # Creates a solr document hash for the {#object}
    # @yield [Hash] yields the solr document
    # @return [Hash] the solr document
    def generate_solr_document
      solr_doc = {}
      Solrizer.set_field(solr_doc, 'system_create', c_time, :stored_sortable)
      Solrizer.set_field(solr_doc, 'system_modified', m_time, :stored_sortable)
      Solrizer.set_field(solr_doc, 'active_fedora_model', object.class.inspect, :stored_sortable)
      solr_doc.merge!(QueryResultBuilder::HAS_MODEL_SOLR_FIELD => object.has_model)
      solr_doc.merge!(SOLR_DOCUMENT_ID.to_sym => object.id)
      solr_doc.merge!(self.class.profile_solr_name => profile_service.new(object).export)
      object.attached_files.each do |name, file|
        solr_doc.merge! file.to_solr(solr_doc, name: name.to_s)
      end
      solr_doc = solrize_rdf_assertions(solr_doc)
      yield(solr_doc) if block_given?
      solr_doc
    end

    protected

    def c_time
      c_time = object.create_date.present? ? object.create_date : DateTime.now
      c_time = DateTime.parse(c_time) unless c_time.is_a?(DateTime)
      c_time
    end

    def m_time
      m_time = object.modified_date.present? ? object.modified_date : DateTime.now
      m_time = DateTime.parse(m_time) unless m_time.is_a?(DateTime)
      m_time
    end

    # Serialize the resource's RDF relationships to solr
    # @param [Hash] solr_doc @deafult an empty Hash
    def solrize_rdf_assertions(solr_doc = Hash.new)
      solr_doc.merge rdf_service.new(object).generate_solr_document
    end
  end
end
