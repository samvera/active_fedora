module ActiveFedora
  module WithMetadata
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :MetadataNode
    autoload :SweetJPLTerms
    autoload :DefaultStrategy
    autoload :DefaultSchema
    autoload :DefaultMetadataClassFactory

    included do
      class_attribute :metadata_class_factory
      self.metadata_class_factory = DefaultMetadataClassFactory
    end

    def metadata_node
      @metadata_node ||= self.class.metadata_schema.new(self)
    end

    def create_or_update(*)
      return unless super && !new_record?
      metadata_node.metadata_uri = described_by # TODO: only necessary if the URI was < > before
      metadata_node.save # TODO if changed?
    end

    module ClassMethods
      def metadata(&block)
        @metadata_schema = metadata_class_factory.build(self, &block)
      end

      def metadata_schema
        @metadata_schema ||= metadata_class_factory.build(self)
      end
    end
  end
end
