module ActiveFedora::RDF
  # Responsible for generating the solr document (via #generate_solr_document) of the
  # given object.
  #
  # @see ActiveFedora::Indexing
  # @see ActiveFedora::IndexingService
  class IndexingService
    include Solrizer::Common
    attr_reader :object, :index_config

    # @param [#resource, #rdf_subject] obj the object to build an solr document for. Its class must respond to 'properties'
    # @param [ActiveFedora::Indexing::Map] index_config the configuration to use to map object values to index document values
    def initialize(obj, index_config = nil)
      unless index_config
        Deprecation.warn(self, "initializing ActiveFedora::RDF::IndexingService without an index_config is deprecated and will be removed in ActiveFedora 13.0")
        index_config = obj.class.index_config
      end
      @object = obj
      @index_config = index_config
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
          field_info.values.each do |val|
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
                                           field_info.behaviors, solr_doc)
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
          val.node? ? val.rdf_label : val.rdf_subject.to_s
        else
          val
        end
      end

      def resource
        object.resource
      end

      # returns the field map instance
      def fields
        field_map_class.new do |field_map|
          index_config.each { |name, index_field_config| field_map.insert(name, index_field_config, object) }
        end
      end

      # Override this method to use your own FieldMap class for custom indexing of objects and properties
      def field_map_class
        ActiveFedora::RDF::FieldMap
      end
  end
end
