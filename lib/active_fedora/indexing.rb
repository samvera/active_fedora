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
        c_time = create_date.present? ? create_date : DateTime.now
        c_time = DateTime.parse(c_time) unless c_time.is_a?(DateTime)
        m_time = modified_date.present? ? modified_date : DateTime.now
        m_time = DateTime.parse(m_time) unless m_time.is_a?(DateTime)
        Solrizer.set_field(solr_doc, 'system_create', c_time, :stored_sortable)
        Solrizer.set_field(solr_doc, 'system_modified', m_time, :stored_sortable)
        # Solrizer.set_field(solr_doc, 'object_state', state, :stored_sortable)
        Solrizer.set_field(solr_doc, 'active_fedora_model', self.class.inspect, :stored_sortable)
        solr_doc.merge!(SolrService::HAS_MODEL_SOLR_FIELD => has_model)
        solr_doc.merge!(SOLR_DOCUMENT_ID.to_sym => id)
        solr_doc.merge!(ActiveFedora::Base.profile_solr_name => to_json)
      end
      attached_files.each do |name, ds|
        solr_doc.merge! ds.to_solr(solr_doc, name: name )
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
      self.class.outgoing_reflections.values.each do |reflection|
        value = Array(self[reflection.foreign_key]).compact
        # TODO make reflection.options[:property] a method
        solr_key = solr_name(reflection.options[:property], :symbol)
        value.each do |v|
          ::Solrizer::Extractor.insert_solr_field_value(solr_doc, solr_key, v )
        end
      end
      solr_doc
    end

    # Updates Solr index with self.
    def update_index
      if defined?( Solrizer::Fedora::Solrizer )
        #logger.info("Trying to solrize id: #{id}")
        solrizer = Solrizer::Fedora::Solrizer.new
        solrizer.solrize( self )
      else
        SolrService.add(self.to_solr, softCommit: true)
      end
    end


    module ClassMethods

      def reindex_everything
        get_descendent_uris(ActiveFedora::Base.id_to_uri('')).each do |uri|
          logger.debug "Re-index everything ... #{uri}"
          ActiveFedora::Base.find(LdpResource.new(ActiveFedora.fedora.connection, uri)).update_index
        end
      end

      # This method can be used instead of ActiveFedora::Model::ClassMethods.find.
      # It works similarly except it populates an object from Solr instead of Fedora.
      # It is most useful for objects used in read-only displays in order to speed up loading time.  If only
      # a id is passed in it will query solr for a corresponding solr document and then use it
      # to populate this object.
      #
      # If a value is passed in for optional parameter solr_doc it will not query solr again and just use the
      # one passed to populate the object.
      #
      # It will anything stored within solr such as metadata and relationships.  Non-metadata attached files will not
      # be loaded and if needed you should use find instead.
      def load_instance_from_solr(id, solr_doc=nil)
        SolrInstanceLoader.new(self, id, solr_doc).object
      end

      def get_descendent_uris(uri)
        resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
        immediate_descendent_uris = resource.graph.query(predicate: RDF::LDP.contains).map { |descendent| descendent.object.to_s }
        all_descendents_uris = [uri]
        immediate_descendent_uris.each do |descendent_uri|
          all_descendents_uris += get_descendent_uris(descendent_uri)
        end
        all_descendents_uris
      end

    end

  end
end
