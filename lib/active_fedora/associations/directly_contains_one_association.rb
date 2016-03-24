module ActiveFedora
  module Associations
    # Filters a DirectContainer relationship, returning the first item that matches the given :type
    class DirectlyContainsOneAssociation < SingularAssociation #:nodoc:
      # Finds objects contained by the container predicate (either the configured has_member_relation or ldp:contains)
      # TODO: Refactor this to use solr (for efficiency) instead of parsing the RDF graph.  Requires indexing ActiveFedora::File objects into solr, including their RDF.type and, if possible, the id of their container
      def find_target
        # filtered_objects = container_association_proxy.to_a.select { |o| o.metadata_node.type.include?(options[:type]) }
        query_node = if container_predicate = options[:has_member_relation]
                       owner
                     else
                       container_predicate = ::RDF::Vocab::LDP.contains
                       container_association.container # Use the :through association's container
                     end

        contained_uris = query_node.resource.query(predicate: container_predicate).map { |r| r.object.to_s }
        contained_uris.each do |object_uri|
          contained_object = klass.find(klass.uri_to_id(object_uri))
          return contained_object if get_type_from_record(contained_object).include?(options[:type])
        end
        nil # if nothing was found & returned while iterating on contained_uris, return nil
      end

      # Adds record to the DirectContainer identified by the container_association
      # Relies on container_association.initialize_attributes to appropriately set things like record.uri
      def add_to_container(record)
        container_association.add_to_target(record) # adds record to corresponding Container
        # TODO is send necessary?
        container_association.send(:initialize_attributes, record) # Uses the :through association initialize the record with things like the correct URI for a direclty contained object
      end

      # Replaces association +target+ with +record+
      # Ensures that this association's +type+ is set on the record and adds the record to the association's DirectContainer
      def replace(record, *)
        if record
          raise_on_type_mismatch!(record)
          remove_existing_target
          add_type_to_record(record, options[:type])
          add_to_container(record)
        else
          remove_existing_target
        end

        self.target = record
      end

      def updated?
        @updated
      end

      private

        def remove_existing_target
          @target ||= find_target
          return unless @target
          container_association_proxy.delete @target
          @updated = true
        end

        # Overrides initialize_attributes to ensure that record is initialized with attributes from the corresponding container
        def initialize_attributes(record)
          super
          container_association.initialize_attributes(record)
        end

        # Returns the Reflection corresponding to the direct container association that's being filtered
        def container_reflection
          @container_reflection ||= @owner.class._reflect_on_association(@reflection.options[:through])
        end

        # Returns the DirectContainerAssociation corresponding to the direct container that's being filtered
        def container_association
          container_association_proxy.proxy_association
        end

        # Returns the ContainerAssociationProxy corresponding to the direct container that's being filtered
        def container_association_proxy
          @owner.send(@reflection.options[:through])
        end

        # Adds type_uri to the RDF.type assertions on record
        def add_type_to_record(record, type_uri)
          metadata_node = metadata_node_for_record(record)
          types = metadata_node.type
          unless types.include?(type_uri)
            types << type_uri
            metadata_node.set_value(:type, types)
          end
          record
        end

        # Returns the RDF.type assertions for the record
        def get_type_from_record(record)
          metadata_node_for_record(record).type
        end

        # Returns the RDF node that contains metadata like RDF.type assertions for the record
        # Sometimes this is the record, other times it's record.metadata_node
        def metadata_node_for_record(record)
          return record if record.respond_to?(:type) && record.respond_to?(:set_value)
          return record.metadata_node if record.respond_to?(:metadata_node)
          raise ArgumentError, "record must either have a metadata node or must respond to .type"
        end
    end
  end
end
