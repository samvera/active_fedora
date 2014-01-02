module ActiveFedora
  module Rdf
    module Indexing
      extend ActiveSupport::Concern

      def prefix(name)
        self.class.prefix(dsid, name)
      end

      def to_solr(solr_doc = Hash.new) # :nodoc:
        fields.each do |field_key, field_info|
          values = get_values(rdf_subject, field_key)
          Array(values).each do |val|    
            val = val.to_s if val.kind_of? RDF::URI
            Solrizer.insert_field(solr_doc, prefix(field_key), val, *field_info[:behaviors])
          end
        end
        solr_doc
      end


      module ClassMethods
        def prefix(dsid, name)
          "#{dsid.underscore}__#{name}".to_sym
        end

        # Gives the primary solr name for a column. If there is more than one indexer on the field definition, it gives the first 
        def primary_solr_name(dsid, field)
          config = config_for_term_or_uri(field)
          if behaviors = config.behaviors
            ActiveFedora::SolrService.solr_name(prefix(dsid, field), behaviors.first, type: config.type)
          end
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
