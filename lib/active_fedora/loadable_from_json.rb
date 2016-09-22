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

      def term_values(*terminology)
        @hash.fetch(terminology.first, [])
      end

      # It is expected that the singular filter gets applied after fetching the value from this
      # resource, so cast everything back to an array.
      def update_indexed_attributes(hash)
        hash.each do |k, v|
          @hash[k.first] = Array(v)
        end
      end

      attr_writer :uri
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

      def persist!(*)
        true
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
          @values.map { |v| FakeStatement.new(v) }
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

      def query(args = {})
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
        k = reflection(pred)
        if @hash[k].is_a?(Array)
          set_value(k, @hash[k] << val)
        else
          set_value(k, [val])
        end
      end

      # Find the reflection on the model that uses the given predicate
      def reflection(predicate)
        result = Array(@model.outgoing_reflections.find { |_key, reflection| reflection.predicate == predicate }).first
        return result if result
        fail "Unable to find reflection for #{predicate} in #{@model}"
      end
    end

    # @param json [String] json to be parsed into attributes
    # @yield [self] Yields self after attributes from json have been assigned
    #               but before callbacks and before the object is frozen.
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
      # TODO: Should we clear the change tracking, or make this object Read-only?

      yield self if block_given?

      run_callbacks :find
      run_callbacks :initialize
      freeze
      self
    end

    private

      # Adapt attributes read from Solr to fit the data model.
      # @param attrs [Hash] attributes read from Solr
      # @return [Hash] the adapted attributes
      def adapt_attributes(attrs)
        self.class.attribute_names.each_with_object({}) do |attribute_name, new_attributes|
          new_attributes[attribute_name] = adapt_attribute_value(attrs, attribute_name)
        end
      end

      # Adapts a single attribute from the given attributes hash to fit the data
      # model.
      # @param attrs [Hash] attributes read from Solr
      # @param attribute_name [String] the name of the attribute to adapt
      # @return [Object] the adapted value
      def adapt_attribute_value(attrs, attribute_name)
        reflection = property_reflection(attribute_name)
        # if this isn't a property, copy value verbatim
        return attrs[attribute_name] unless reflection
        multiple = reflection.multiple?
        # if value is missing in attrs, return [] or nil as appropriate
        return multiple ? [] : nil unless attrs.key?(attribute_name)

        if multiple
          Array(attrs[attribute_name]).map do |value|
            adapt_single_attribute_value(value, attribute_name)
          end
        else
          adapt_single_attribute_value(attrs[attribute_name], attribute_name)
        end
      end

      def property_reflection(attribute_name)
        self.class.reflect_on_property(attribute_name)
      rescue ActiveTriples::UndefinedPropertyError
        ActiveFedora::Base.logger.info "Undefined property #{attribute_name} reflected."
        nil
      end

      def date_attribute?(attribute_name)
        reflection = self.class.reflect_on_property(attribute_name)
        return false unless reflection
        reflection.type == :date || reflection.class_name == DateTime
      end

      # Adapts a single attribute value to fit the data model. If the attribute
      # is multi-valued, each value is passed separately to this method.
      # @param value [Object] attribute value read from Solr
      # @param attribute_name [String] the name of the attribute to adapt
      # @return [Object] the adapted value
      def adapt_single_attribute_value(value, attribute_name)
        if value && date_attribute?(attribute_name)
          return nil unless value.present?
          DateTime.parse(value)
        else
          value
        end
      end
  end
end
