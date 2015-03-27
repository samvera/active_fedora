module ActiveFedora::RDF
  class IndexingService
    include Solrizer::Common
    attr_reader :object

    # @param obj [#resource, #rdf_subject] the object to build an solr document for. Its class must respond to 'properties'
    # @param prefix_method [Lambda] This method gets the original name of the field and the options passed in. It should return the name of the field in the solr document
    def initialize(obj)
      @object = obj
    end

    # Creates a solr document hash for the rdf assertions of the {#object}
    # @yield [Hash] yields the solr document
    # @return [Hash] the solr document
    def generate_solr_document(prefix_method = nil)
      solr_doc = add_assertions(prefix_method)
      yield(solr_doc) if block_given?
      solr_doc
    end

    protected

      def add_assertions(prefix_method, solr_doc = {})
        fields.each do |field_key, field_info|
          solr_field_key = solr_document_field_name(field_key, prefix_method)
          Array(field_info[:values]).each do |val|
            append_to_solr_doc(solr_doc, solr_field_key, field_info, val)
          end
        end
        solr_doc
      end

      # Override this in order to allow one field to be expanded into more than one:
      #   example:
      #     def append_to_solr_doc(solr_doc, field_key, field_info, val)
      #       Solrizer.set_field(solr_doc, 'lcsh_subject_uri', val.to_uri, :symbol)
      #       Solrizer.set_field(solr_doc, 'lcsh_subject_label', val.to_label, :searchable)
      #     end
      def append_to_solr_doc(solr_doc, solr_field_key, field_info, val)
        self.class.create_and_insert_terms(solr_field_key,
                                           solr_document_field_value(val),
                                           field_info[:behaviors], solr_doc)
      end

      def solr_document_field_name(field_key, prefix_method)
        if prefix_method
          prefix_method.call(field_key)
        else
          field_key.to_s
        end
      end

      def solr_document_field_value(val)
        case val
          when ::RDF::URI
            val.to_s
          when ActiveTriples::Resource
            val.solrize
          else
            val
        end
      end

      def resource
        object.resource
      end

      def properties
        object.class.properties
      end

      def index_config
        object.class.index_config
      end

      # returns a Hash, e.g.: {field => { values: [], type: :something, behaviors: [] }, ...}
      def fields
        field_map = {}.with_indifferent_access

        index_config.each do |name, index_field_config|
          type = index_field_config.data_type
          behaviors = index_field_config.behaviors
          next unless type and behaviors
          next if kind_of_af_base?(name)
          field_map[name] = { values: find_values(name), type: type, behaviors: behaviors}
        end
        field_map
      end

      def kind_of_af_base?(name)
        config = properties[name.to_s]
        config && config[:class_name] && config[:class_name] < ActiveFedora::Base
      end

      def find_values(name)
        object.send(name) || []
      end
  end
end
