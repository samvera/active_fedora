module ActiveFedora
  module RDF
    module Indexing
      extend ActiveSupport::Concern
      included do
        include Solrizer::Common
      end

      def apply_prefix(name, file_path)
        name.to_s
      end

      def to_solr(solr_doc={}, opts={}) # :nodoc:
        super.tap do |solr_doc|
          fields.each do |field_key, field_info|
            values = resource.get_values(field_key)
            Array(values).each do |val|
              if val.kind_of? ::RDF::URI
                val = val.to_s
              elsif val.kind_of? ActiveTriples::Resource
                val = val.solrize
              end
              self.class.create_and_insert_terms(apply_prefix(field_key, opts[:name]), val, field_info[:behaviors], solr_doc)
            end
          end
        end
      end

      # Gives the primary solr name for a column. If there is more than one indexer on the field definition, it gives the first
      def primary_solr_name(field, file_path)
        config = self.class.config_for_term_or_uri(field)
        return nil unless config # punt on index names for deep nodes!
        if behaviors = config.behaviors
          behaviors.each do |behavior|
            result = ActiveFedora::SolrQueryBuilder.solr_name(apply_prefix(field, file_path), behavior, type: config.type)
            return result if Solrizer::DefaultDescriptors.send(behavior).evaluate_suffix(:text).stored?
          end
          raise RuntimeError "no stored fields were found"
        end
      end

      module ClassMethods
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
