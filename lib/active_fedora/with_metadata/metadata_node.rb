module ActiveFedora
  module WithMetadata
    class MetadataNode < ActiveTriples::Resource
      include ActiveModel::Dirty
      attr_reader :file

      # mime_type is treated differently than all the other metadata properties,
      # in that it can be set at file-create time (as a HTTP post header) and be
      # updated (using SPARQL update) on the metadata-node.  Therefore, it is in
      # this class rather than being in the DefaultSchema.
      property :mime_type, predicate: ::RDF::Vocab::EBUCore.hasMimeType

      # @param file [ActiveFedora::File]
      def initialize(file)
        @file = file
        super(file.uri, ldp_source.graph)
        return unless self.class.type && !type.include?(self.class.type)
        attributes_changed_by_setter[:type] = true if type.present?
        # Workaround for https://github.com/ActiveTriples/ActiveTriples/issues/123
        get_values(:type) << self.class.type
      end

      attr_writer :metadata_uri

      def metadata_uri
        @metadata_uri ||= if file.new_record?
                            ::RDF::URI.new nil
                          else
                            raise "#{file} must respond_to described_by" unless file.respond_to? :described_by
                            file.described_by
                          end
      end

      def set_value(*args)
        super
        attribute_will_change! args.first
      end

      def ldp_source
        @ldp_source ||= LdpResource.new(ldp_connection, nil) if file.new_record?
        @ldp_source ||= LdpResource.new(ldp_connection, metadata_uri)
      end

      def ldp_connection
        ActiveFedora.fedora.connection
      end

      def save
        raise "Save the file first" if file.new_record?
        SparqlInsert.new(changes_for_update, file.uri).execute(metadata_uri)
        @ldp_source = nil
        @metadata_uri = nil
        true
      end

      def changed_attributes
        super.tap do |changed|
          changed.merge('type' => true) if type.present? && new_record?
        end
      end

      # Conform to the ActiveFedora::Base API
      def association(_)
        []
      end

      private

        def changes_for_update
          ChangeSet.new(self, self, changed_attributes.keys).changes
        end

        class << self
          attr_writer :parent_class

          attr_reader :parent_class

          def property(name, options)
            parent_class.delegate name, :"#{name}=", :"#{name}_changed?", to: :metadata_node
            super
          end

          def create_delegating_setter(name)
            file.class.delegate(name, to: :metadata_node)
          end

          def exec_block(&block)
            class_eval(&block)
          end
        end
    end
  end
end
