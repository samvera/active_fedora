module ActiveFedora
  ##
  # Implement the .apply_schema method from ActiveTriples to allow for
  # externally defined schemas to be put on an AF::Base object.
  module Schema
    extend ActiveSupport::Concern

    module ClassMethods
      def apply_schema(schema, strategy=ActiveFedora::SchemaIndexingStrategy.new)
        schema.properties.each do |property|
          strategy.apply(self, property)
        end
      end
    end
  end
end
