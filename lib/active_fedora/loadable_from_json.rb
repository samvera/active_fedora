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
        def initialize(values)
          @values = values || []
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
      self.attributes = attrs.slice(*self.class.attribute_names)
      # TODO Should we clear the change tracking, or make this object Read-only?

      run_callbacks :find
      run_callbacks :initialize
      freeze
      self
    end

  end
end
