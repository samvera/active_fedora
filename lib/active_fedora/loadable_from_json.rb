module ActiveFedora
  module LoadableFromJson
    extend ActiveSupport::Concern

    class SolrBackedMetadataFile
      def freeze
        @hash.freeze
      end

      def initialize
        @hash = {}
      end

      def term_values *terminology
        @hash.fetch(terminology.first, [])
      end

      # It is expected that the singular filter gets applied after fetching the value from this
      # resource, so cast everything back to an array.
      def update_indexed_attributes hash
        hash.each do |k, v|
          @hash[k.first] = Array(v)
        end
      end

      def uri= uri
        @uri = uri
      end
    end

    class SolrBackedResource
      def freeze
        @hash.freeze
      end

      def initialize(model)
        @model = model
        @hash = {}
      end

      def to_s
        @hash.to_s
      end

      # It is expected that the singular filter gets applied after fetching the value from this
      # resource, so cast everything back to an array.
      def set_value(k, v)
        @hash[k] = Array(v)
      end

      def get_values(k)
        @hash[k]
      end

      # FakeQuery exists to adapt the hash to the RDF interface used by RDF associations in ActiveFedora
      class FakeQuery
        include ::Enumerable

        def initialize(values)
          @values = values || []
        end

        def each(&block)
          enum_statement.each(&block)
        end

        def enum_statement
          @values.map {|v| FakeStatement.new(v) }
        end

        def objects
          @values
        end

        class FakeStatement
          def initialize(value)
            @value = value
          end

          def object
            @value
          end
        end
      end

      def query(args={})
        predicate = args[:predicate]
        reflection = reflection(predicate)
        FakeQuery.new(get_values(reflection))
      end

      def rdf_subject
        ::RDF::URI.new(nil)
      end

      # Called by Associations::RDF#replace to add data to this resource represenation
      # @param [Array] vals an array of 3 elements (subject, predicate, object) to insert
      def insert(vals)
        _, pred, val = vals
        set_value(reflection(pred), [val])
      end

      def reflection(predicate)
        Array(@model.outgoing_reflections.find { |key, reflection| reflection.predicate == predicate }).first
      end
    end

    # @param json [String] json to be parsed into attributes
    def init_with_json(json)
      attrs = JSON.parse(json)
      id = attrs.delete('id')

      @ldp_source = build_ldp_resource(id)
      @association_cache = {}
      datastream_keys = self.class.child_resource_reflections.keys
      datastream_keys.each do |key|
        attached_files[key] = SolrBackedMetadataFile.new
      end
      @resource = SolrBackedResource.new(self.class)
      self.attributes = adapt_attributes(attrs)
      # TODO Should we clear the change tracking, or make this object Read-only?

      run_callbacks :find
      run_callbacks :initialize
      freeze
      self
    end

    private

      # Adapt attributes read from Solr to possible minor changes in data model
      # since the attributes were saved.
      # @param attrs [Hash] attributes read from Solr
      # @return [Hash] the adapted attributes
      def adapt_attributes(attrs)
        self.class.attribute_names.each_with_object({}) do |attribute_name, new_attributes|
          new_attributes[attribute_name] = adapt_attribute_value(attrs, attribute_name)
        end
      end

      # Adapts a single attribute value from the given attributes hash to match
      # minor changes in the data model.
      # @param attrs [Hash] attributes read from Solr
      # @param attribute_name [String] the name of the attribute to adapt
      # @return [Object] the adapted value
      def adapt_attribute_value(attrs, attribute_name)
        reflection = self.class.reflect_on_property(attribute_name)
        if !reflection
          return attrs[attribute_name] # if this isn't a property, copy value verbatim
        else
          multiple = reflection.multiple?
          if !attrs.key?(attribute_name)
            # value is missing in attrs, add [] or nil
            return multiple ? [] : nil
          else
            # convert an existing scalar to an array if needed
            return multiple ? Array(attrs[attribute_name]) : attrs[attribute_name]
          end
        end
      end

  end
end
