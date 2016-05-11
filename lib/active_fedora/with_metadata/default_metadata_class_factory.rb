# This builds classes for metadata nodes (nodes that describe a binary)
module ActiveFedora::WithMetadata
  class DefaultMetadataClassFactory
    class_attribute :metadata_base_class, :file_metadata_schemas, :file_metadata_strategy
    self.metadata_base_class = MetadataNode
    self.file_metadata_schemas = [DefaultSchema]
    self.file_metadata_strategy = DefaultStrategy

    class << self
      def build(parent, &block)
        create_class(parent).tap do |resource_class|
          file_metadata_schemas.each do |schema|
            resource_class.apply_schema(schema, file_metadata_strategy)
          end
          resource_class.exec_block(&block) if block_given?
        end
      end

      private

        # Make a subclass of MetadataNode named GeneratedMetadataSchema and set its
        # parent_class attribute to have the value of the current class.
        def create_class(parent_klass)
          Class.new(metadata_base_class).tap do |klass|
            parent_klass.const_set(:GeneratedMetadataSchema, klass)
            klass.parent_class = parent_klass
          end
        end
    end
  end
end
