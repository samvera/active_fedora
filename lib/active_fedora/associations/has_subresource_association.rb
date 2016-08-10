module ActiveFedora
  module Associations
    class HasSubresourceAssociation < SingularAssociation #:nodoc:
      # Implements the reader method, e.g. foo.bar for Foo.has_one :bar
      def reader(force_reload = false)
        super || build
      end

      def find_target
        find_or_initialize_target do |record|
          configure_datastream(record) if reflection.options[:block]
        end
      end

      def target_uri
        "#{owner.id}/#{reflection.name}"
      end

      private

        def raise_on_type_mismatch!(record)
          return if record.is_a? LoadableFromJson::SolrBackedMetadataFile
          super
        end

        def find_or_initialize_target(&block)
          if reflection.klass < ActiveFedora::File
            reflection.build_association(id: target_uri, &block)
          else
            reflection.klass.find(target_uri)
          end
        rescue ActiveFedora::ObjectNotFoundError
          reflection.build_association(id: target_uri, &block)
        end

        def replace(record)
          if record
            raise_on_type_mismatch!(record)
            @updated = true
          end

          self.target = record
        end

        def new_record(method, attributes)
          record = super
          configure_datastream(record)
          record
        end

        def configure_datastream(record)
          # If you called has_metadata with a block, pass the block into the File class
          if reflection.options[:block].class == Proc
            reflection.options[:block].call(record)
          end
          return unless record.new_record? && reflection.options[:autocreate]
          record.datastream_will_change!
        end
    end
  end
end
