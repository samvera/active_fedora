module ActiveFedora
  ##
  # Implement the .apply_schema method from ActiveTriples to allow for
  # externally defined schemas to be put on an AF::Base object.
  module Schema
    extend ActiveSupport::Concern

    module ClassMethods
      # Applies a schema to an ActiveFedora::Base.
      # @note The default application strategy adds no indexing hints. You may
      #   want to implement a different strategy if you want to set values on the
      #   property reflection.
      # @param schema [ActiveTriples::Schema] The schema to apply.
      # @param strategy [#apply] The strategy to use for applying the schema.
      # @example Apply a schema and index everything as symbol.
      #   apply_schema MySchema, ActiveFedora::SchemaIndexingStrategy.new(
      #     ActiveFedora::GlobalIndexer.new(:symbol)
      #   )
      def apply_schema(schema, strategy = ActiveFedora::SchemaIndexingStrategy.new)
        schema.properties.each do |property|
          strategy.apply(self, property)
        end
      end
    end
  end
end
