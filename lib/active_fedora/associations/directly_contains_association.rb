module ActiveFedora
  module Associations
    class DirectlyContainsAssociation < ContainsAssociation #:nodoc:
      def insert_record(record, force = true, validate = true)
        container.save!
        super
      end

      def find_target
        query_node = if container_predicate = options[:has_member_relation]
                       owner
                     else
                       container_predicate = ::RDF::Vocab::LDP.contains
                       container
                     end

        uris = query_node.resource.query(predicate: container_predicate).map { |r| r.object.to_s }

        uris.map { |object_uri| klass.find(klass.uri_to_id(object_uri)) }
      end

      def container
        @container ||= begin
          DirectContainer.find_or_initialize(ActiveFedora::Base.uri_to_id(uri)).tap do |container|
            container.parent = @owner
            container.has_member_relation = Array(options[:has_member_relation])
            container.is_member_of_relation = Array(options[:is_member_of_relation])
          end
        end
      end

      protected

        def initialize_attributes(record) #:nodoc:
          record.uri = ActiveFedora::Base.id_to_uri(container.mint_id)
          set_inverse_instance(record)
        end
    end
  end
end
