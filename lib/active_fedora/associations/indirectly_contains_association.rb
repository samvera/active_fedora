module ActiveFedora
  module Associations
    # TODO: we may want to split this into two subclasses, one for has_member_relation
    # and the other for is_member_of_relation
    class IndirectlyContainsAssociation < ContainsAssociation #:nodoc:
      # Add +records+ to this association.  Returns +self+ so method calls may be chained.
      # Since << flattens its argument list and inserts each record, +push+ and +concat+ behave identically.
      def concat(*records)
        concat_records(records)
      end

      def insert_record(record, force = true, validate = true)
        container.save!
        if force
          record.save!
        else
          return false unless record.save(validate: validate)
        end

        save_through_record(record)

        true
      end

      # Implements the ids reader method, e.g. foo.item_ids for
      # Foo.indirectly_contains :items, ...
      def ids_reader
        predicate = reflection.options.fetch(:has_member_relation)
        if loaded?
          target.map(&:id)
        else
          owner.resource.query(predicate: predicate)
               .map { |s| ActiveFedora::Base.uri_to_id(s.object) } | target.map(&:id)
        end
      end

      def find_target
        if container_predicate = options[:has_member_relation]
          uris = owner.resource.query(predicate: container_predicate).map { |r| r.object.to_s }
          uris.map { |object_uri| klass.find(klass.uri_to_id(object_uri)) }
        else # is_member_of_relation
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

        def initialize_attributes(_record) #:nodoc:
          # record.uri = ActiveFedora::Base.id_to_uri(container.mint_id)
          # set_inverse_instance(record)
        end

      private

        def delete_records(records, _method)
          container.reload # Reload container to get updated LDP.contains
          records.each do |record|
            delete_record(record)
          end
        end

        def delete_record(record)
          record_proxy_finder.find(record).delete
        end

        def record_proxy_finder
          ContainedFinder.new(container: container, repository: composite_proxy_repository, proxy_class: proxy_class)
        end

        def composite_proxy_repository
          RecordComposite::Repository.new(base_repository: proxy_class)
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
