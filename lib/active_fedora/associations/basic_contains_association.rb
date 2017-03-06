module ActiveFedora
  module Associations
    class BasicContainsAssociation < ContainsAssociation #:nodoc:
      def find_target
        uris = owner.resource.query(predicate: options[:predicate])
                    .map { |r| r.object.to_s }

        uris.map { |object_uri| klass.find(klass.uri_to_id(object_uri)) }
      end

      def insert_record(record, force = true, validate = true)
        record.base_path_for_resource = owner.uri.to_s
        super
      end

      def add_to_target(record, skip_callbacks = false)
        record.base_path_for_resource = owner.uri.to_s
        super
      end

      def reset
        # Update the membership triples (and no other triples) on the the owner's resource
        if owner.persisted?
          pattern = ::RDF::Query::Pattern.new(predicate: options[:predicate])
          new_resource = ActiveFedora::Base.uncached do
            owner.dup.reload.resource
          end
          owner.resource.delete_insert([pattern], new_resource.query(pattern))
        end
        super
      end
    end
  end
end
