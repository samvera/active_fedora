module ActiveFedora
  module WithMetadata
    class MetadataNode < ActiveTriples::Resource
      include ActiveModel::Dirty
      attr_reader :file

      def initialize(file)
        @file = file
        super(file.uri, ldp_source.graph)
      end

      def metadata_uri= uri
        @metadata_uri = uri
      end

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
        @ldp_source ||= LdpResource.new(ldp_connection, metadata_uri)
      end

      def ldp_connection
        ActiveFedora.fedora.connection
      end

      def save
        raise "Save the file first" if file.new_record?
        change_set = ChangeSet.new(self, self, changed_attributes.keys)
        SparqlInsert.new(change_set.changes, ::RDF::URI.new(file.uri)).execute(metadata_uri)
        @ldp_source = nil
        true
      end

      class << self
        def parent_class= parent
          @parent_class = parent
        end

        def parent_class
          @parent_class
        end

        def property(name, options)
          parent_class.delegate name, :"#{name}=", :"#{name}_changed?", to: :metadata_node
          super
        end

        def create_delegating_setter(name)
          file.class.delegate(name, to: :metadata_node)
        end

        def exec_block(&block)
          class_eval &block
        end
      end
    end
  end
end
