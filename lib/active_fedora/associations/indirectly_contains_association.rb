module ActiveFedora
  module Associations
    class IndirectlyContainsAssociation < ContainsAssociation #:nodoc:

      def insert_record(record, force = true, validate = true)
        container.save!
        if force
          record.save!
        else
          return false unless record.save(validate: validate)
        end

        save_through_record(record)

        return true
      end

      def delete_records(records, method)
        container.reload # Reload container to get updated LDP.contains
        records.each do |record|
          delete_record(record)
        end
      end

      def find_target
        if container_predicate = options[:has_member_relation]
          uris = owner.resource.query(predicate: container_predicate).map { |r| r.object.to_s }
          uris.map { |object_uri| klass.find(klass.uri_to_id(object_uri)) }
        else
          # TODO this is a lot of reads. Avoid this path
          container_predicate = ::RDF::Vocab::LDP.contains
          proxy_uris = container.resource.query(predicate: container_predicate).map { |r| r.object.to_s }
          proxy_uris.map { |uri| proxy_class.find(proxy_class.uri_to_id(uri))[options[:foreign_key]] }
        end


      end

      def container
        @container ||= begin
          IndirectContainer.find_or_initialize(ActiveFedora::Base.uri_to_id(uri)).tap do |container|
            container.parent = @owner
            container.has_member_relation = Array(options[:has_member_relation])
            container.is_member_of_relation = Array(options[:is_member_of_relation])
            container.inserted_content_relation = Array(options[:inserted_content_relation])
          end
        end
      end

      protected

        def initialize_attributes(record) #:nodoc:
          #record.uri = ActiveFedora::Base.id_to_uri(container.mint_id)
          # set_inverse_instance(record)
        end

      private

        def delete_record(record)
          proxy_ids = RecordProxyFinder.new(container: container).call(record)
          DeleteProxy.call(proxy_ids: proxy_ids, proxy_class: proxy_class)
        end

        def save_through_record(record)
          build_proxy_node({}) do |node|
            node[options[:foreign_key]] = record
            node.save
          end
        end

        def build_proxy_node(attributes, &block)
          proxy_class.new({ id: container.mint_id }.merge(attributes), &block)
        end

        def proxy_class
          @proxy_class ||= options[:through].constantize
        end
    end
  end
end
