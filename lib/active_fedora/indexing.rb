module ActiveFedora
  module Indexing
    extend ActiveSupport::Concern

    # Return a Hash representation of this object where keys in the hash are appropriate Solr field names.
    # @param [Hash] solr_doc (optional) Hash to insert the fields into
    # @param [Hash] opts (optional)
    # If opts[:model_only] == true, the base object metadata and the RELS-EXT datastream will be omitted.  This is mainly to support shelver, which calls .to_solr for each model an object subscribes to.
    def to_solr(solr_doc = Hash.new, opts={})
      indexing_service.generate_solr_document
    end

    def indexing_service
      @indexing_service ||= self.class.indexer.new(self)
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

      def indexer
        IndexingService
      end

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
