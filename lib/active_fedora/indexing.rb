module ActiveFedora
  module Indexing
    extend ActiveSupport::Concern

    included do
      class_attribute :profile_solr_name
      self.profile_solr_name = ActiveFedora::SolrService.solr_name("object_profile", :displayable)
    end

    # Return a Hash representation of this object where keys in the hash are appropriate Solr field names.
    # @param [Hash] solr_doc (optional) Hash to insert the fields into
    # @param [Hash] opts (optional)
    # If opts[:model_only] == true, the base object metadata and the RELS-EXT datastream will be omitted.  This is mainly to support shelver, which calls .to_solr for each model an object subscribes to.
    def to_solr(solr_doc = Hash.new, opts={})
      unless opts[:model_only]
        c_time = create_date || Time.now
        c_time = Time.parse(c_time) unless c_time.is_a?(Time)
        m_time = modified_date || Time.now
        m_time = Time.parse(m_time) unless m_time.is_a?(Time)
        Solrizer.set_field(solr_doc, 'system_create', c_time, :stored_sortable)
        Solrizer.set_field(solr_doc, 'system_modified', m_time, :stored_sortable)
        # Solrizer.set_field(solr_doc, 'object_state', state, :stored_sortable)
        Solrizer.set_field(solr_doc, 'active_fedora_model', self.class.inspect, :stored_sortable)
        solr_doc.merge!(SolrService::HAS_MODEL_SOLR_FIELD => self.has_model)
        solr_doc.merge!(SOLR_DOCUMENT_ID.to_sym => pid)
      end
      datastreams.each_value do |ds|
        solr_doc.merge! ds.to_solr()
      end
      solr_doc = solrize_relationships(solr_doc) unless opts[:model_only]
      solr_doc
    end

    def solr_name(*args)
      ActiveFedora::SolrService.solr_name(*args)
    end

    # Serialize the datastream's RDF relationships to solr
    # @param [Hash] solr_doc @deafult an empty Hash
    def solrize_relationships(solr_doc = Hash.new)
      outgoing_reflections.each do |reflection|
        key = reflection.foreign_key
        value = self[key]
        # TODO make reflection.options[:property] a method
        solr_key = solr_name(reflection.options[:property], :symbol)
        ::Solrizer::Extractor.insert_solr_field_value(solr_doc, solr_key, value )
      end
      solr_doc
    end

    # Updates Solr index with self.
    def update_index
      if defined?( Solrizer::Fedora::Solrizer )
        #logger.info("Trying to solrize pid: #{pid}")
        solrizer = Solrizer::Fedora::Solrizer.new
        solrizer.solrize( self )
      else
        SolrService.add(self.to_solr, softCommit: true)
      end
    end


    module ClassMethods

      # Using the fedora search (not solr), get every object and reindex it.
      # @param [String] query a string that conforms to the query param format
      #   of the underlying search's API
      def reindex_everything(query = nil)
        #TODO this is broken because it's a fedora3 api
        # we should write a Sparql query: all things where fcrepo:mixinTypes is fedora:object 
        raise "not implemented"
        # big_list_of_node_ids.each do |id|
        #   ActiveFedora::Base.find(id).update_index
        # end
      end

    end

    private
      def outgoing_reflections
        reflections.values.select { |reflection| reflection.has_and_belongs_to_many? || reflection.belongs_to? }
      end
  end
end
