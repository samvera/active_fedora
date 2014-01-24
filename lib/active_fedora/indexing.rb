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
        c_time = create_date
        c_time = Time.parse(c_time) unless c_time.is_a?(Time)
        m_time = modified_date
        m_time = Time.parse(m_time) unless m_time.is_a?(Time)
        Solrizer.set_field(solr_doc, 'system_create', c_time, :stored_sortable)
        Solrizer.set_field(solr_doc, 'system_modified', m_time, :stored_sortable)
        Solrizer.set_field(solr_doc, 'object_state', state, :stored_sortable)
        Solrizer.set_field(solr_doc, 'active_fedora_model', self.class.inspect, :stored_sortable)
        solr_doc.merge!(SOLR_DOCUMENT_ID.to_sym => pid)
        solrize_profile(solr_doc)
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

    def solrize_profile(solr_doc = Hash.new) # :nodoc:
      profile_hash = { 'datastreams' => {} }
      if inner_object.respond_to? :profile
        inner_object.profile.each_pair do |property,value|
          if property =~ /Date/
            value = Time.parse(value) unless value.is_a?(Time)
            value = value.xmlschema
          end
          profile_hash[property] = value
        end
      end
      self.datastreams.each_pair { |dsid,ds| profile_hash['datastreams'][dsid] = ds.solrize_profile }
      solr_doc[self.class.profile_solr_name] = profile_hash.to_json
    end

    # Serialize the datastream's RDF relationships to solr
    # @param [Hash] solr_doc @deafult an empty Hash
    def solrize_relationships(solr_doc = Hash.new)
      relationships.each_statement do |statement|
        predicate = Predicates.short_predicate(statement.predicate)
        literal = statement.object.kind_of?(RDF::Literal)
        val = literal ? statement.object.value : statement.object.to_str
        ::Solrizer::Extractor.insert_solr_field_value(solr_doc, solr_name(predicate, :symbol), val )
      end
      return solr_doc
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
      # This method can be used instead of ActiveFedora::Model::ClassMethods.find.
      # It works similarly except it populates an object from Solr instead of Fedora.
      # It is most useful for objects used in read-only displays in order to speed up loading time.  If only
      # a pid is passed in it will query solr for a corresponding solr document and then use it
      # to populate this object.
      #
      # If a value is passed in for optional parameter solr_doc it will not query solr again and just use the
      # one passed to populate the object.
      #
      # It will anything stored within solr such as metadata and relationships.  Non-metadata datastreams will not
      # be loaded and if needed you should use find instead.
      def load_instance_from_solr(pid,solr_doc=nil)
        SolrInstanceLoader.new(self, pid, solr_doc).object
      end

      # Using the fedora search (not solr), get every object and reindex it.
      # @param [String] query a string that conforms to the query param format
      #   of the underlying search's API
      def reindex_everything(query = nil)
        connections.each do |conn|
          conn.search(query) do |object|
            next if object.pid.start_with?('fedora-system:')
            ActiveFedora::Base.find(object.pid).update_index
          end
        end
      end

      private

      def connections
        if ActiveFedora.config.sharded?
          return ActiveFedora.config.credentials.map { |cred| ActiveFedora::RubydoraConnection.new(cred).connection}
        else
          return [ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials).connection]
        end
      end
    end
  end
end
