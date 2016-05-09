# This builds classes for metadata nodes (nodes that describe a binary)
module ActiveFedora
  class DefaultMetadataClassFactory
    class_attribute :metadata_base_class
    self.metadata_base_class = WithMetadata::MetadataNode

    def self.build(parent, &block)
      create_class(parent).tap do |schema|
        schema.exec_block(&block) if block_given?
      end
    end

    private
      # Make a subclass of MetadataNode named GeneratedMetadataSchema and set its
      # parent_class attribute to have the value of the current class.
      def self.create_class(parent_klass)
        Class.new(metadata_base_class).tap do |klass|
          parent_klass.const_set(:GeneratedMetadataSchema, klass)
          klass.parent_class = parent_klass
        end
      end
  end
end
