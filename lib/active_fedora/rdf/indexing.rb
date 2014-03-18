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
          values = resource.get_values(field_key)
          Array(values).each do |val|
            if val.kind_of? RDF::URI
              val = val.to_s 
            elsif val.kind_of? Rdf::Resource
              val = val.solrize
            end
            self.class.create_and_insert_terms(apply_prefix(field_key), val, field_info[:behaviors], solr_doc)
          end
        end
        solr_doc
      end

      # Gives the primary solr name for a column. If there is more than one indexer on the field definition, it gives the first 
      def primary_solr_name(field)
        config = self.class.config_for_term_or_uri(field)
        return nil unless config # punt on index names for deep nodes!
        if behaviors = config.behaviors
          behaviors.each do |behavior|
            result = ActiveFedora::SolrService.solr_name(apply_prefix(field), behavior, type: config.type)
            return result if Solrizer::DefaultDescriptors.send(behavior).evaluate_suffix(:text).stored?
          end
          raise RuntimeError "no stored fields were found"
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

          self.class.properties.each do |name, config|
            type = config[:type]
            behaviors = config[:behaviors]
            next unless type and behaviors
            next if config[:class_name] && config[:class_name] < ActiveFedora::Base
            resource.query(:subject => rdf_subject, :predicate => config[:predicate]).each_statement do |statement|
              field_map[name] ||= {:values => [], :type => type, :behaviors => behaviors}
              field_map[name][:values] << statement.object.to_s
            end
          end
          field_map
        end
    end
  end
end
