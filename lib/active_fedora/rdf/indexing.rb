module ActiveFedora
  module Rdf
    module Indexing
      extend Deprecation
      extend ActiveSupport::Concern

      # In active_fedora 8, we can get the prefix part from Datastream.prefix
      def apply_prefix(name)
        "#{dsid.underscore}__#{name}"
      end

      def prefix(name)
        Deprecation.warn Indexing, "prefix is deprecated. Use apply_prefix instead. In active-fedora 8, the prefix method will just return the prefix to be applied, and will not do the applying.  This will enable conformity between OmDatastream and RdfDatastream"
        apply_prefix(name)
      end

      def to_solr(solr_doc = Hash.new) # :nodoc:
        fields.each do |field_key, field_info|
          values = get_values(rdf_subject, field_key)
          Array(values).each do |val|    
            val = val.to_s if val.kind_of? RDF::URI
            Solrizer.insert_field(solr_doc, apply_prefix(field_key), val, *field_info[:behaviors])
          end
        end
        solr_doc
      end

      # Gives the primary solr name for a column. If there is more than one indexer on the field definition, it gives the first 
      def primary_solr_name(field)
        config = self.class.config_for_term_or_uri(field)
        if behaviors = config.behaviors
          ActiveFedora::SolrService.solr_name(apply_prefix(field), behaviors.first, type: config.type)
        end
      end


      module ClassMethods
        def prefix(dsid, name)
          Deprecation.warn Indexing, "prefix is deprecated and will be removed in active-fedora 8.0.0.", caller
          "#{dsid.underscore}__#{name}".to_sym
        end

        # Gives the datatype for a column.
        def type(field)
          config_for_term_or_uri(field).type
        end
      end

      private
        # returns a Hash, e.g.: {field => {:values => [], :type => :something, :behaviors => []}, ...}
        def fields
          field_map = {}.with_indifferent_access

          rdf_subject = self.rdf_subject
          query = RDF::Query.new do
            pattern [rdf_subject, :predicate, :value]
          end

          query.execute(graph).each do |solution|
            predicate = solution.predicate
            value = solution.value
            
            name, config = self.class.config_for_predicate(predicate)
            next unless config
            type = config.type
            behaviors = config.behaviors
            next unless type and behaviors 
            field_map[name] ||= {:values => [], :type => type, :behaviors => behaviors}
            field_map[name][:values] << value.to_s
          end
          field_map
        end
    end
  end
end
