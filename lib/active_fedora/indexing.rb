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
      self.class.outgoing_reflections.values.each do |reflection|
        value = self[reflection.foreign_key]
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

      def reindex_everything
        ids_from_sitemap_index.each do |id|
          logger.debug "Re-index everything ... #{id}"
          ActiveFedora::Base.find(id).update_index
        end
      end

      def ids_from_sitemap_index
        ids = []
        sitemap_index_uri = ActiveFedora::Base.id_to_uri('/sitemap')
        sitemap_index = Nokogiri::XML(open(sitemap_index_uri))
        sitemap_uris = sitemap_index.xpath("//sitemap:loc/text()", sitemap_index.namespaces)
        sitemap_uris.map(&:to_s).each do |sitemap_uri|
          sitemap = Nokogiri::XML(open(sitemap_uri))
          sitemap_ids = sitemap.xpath("//sitemap:loc/text()", sitemap_index.namespaces)
          ids += sitemap_ids.map { |u| ActiveFedora::Base.uri_to_id(u) }
        end
        ids
      end

    end

  end
end
