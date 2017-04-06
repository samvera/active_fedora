module ActiveFedora
  module Indexing
    # Finds all descendent URIs of a given repo URI (usually the base URI).
    #
    # This is a slow and non-performant thing to do, we need to fetch every single
    # object from the repo.
    #
    # The DescendantFetcher is also capable of partitioning the URIs into "priority" URIs
    # that will be first in the returned list. These prioritized URIs belong to objects
    # with certain hasModel models. This feature is used in some hydra apps that need to
    # index 'permissions' objects before other objects to have the solr indexing work right.
    # And so by default, the prioritized class names are the ones form Hydra::AccessControls,
    # but you can alter the prioritized model name list, or set it to the empty array.
    #
    #     DescendantFetcher.new(ActiveFedora.fedora.base_uri).descendent_and_self_uris
    #     #=> array including self uri and descendent uris with "prioritized" (by default)
    #         Hydra::AccessControls permissions) objects FIRST.
    #
    # Change the default prioritized hasModel names:
    #
    #     ActiveFedora::Indexing::DescendantFetcher.default_priority_models = []
    class DescendantFetcher
      HAS_MODEL_PREDICATE = ActiveFedora::RDF::Fcrepo::Model.hasModel

      class_attribute :default_priority_models, instance_accessor: false
      self.default_priority_models = %w(Hydra::AccessControl Hydra::AccessControl::Permissions).freeze

      attr_reader :uri, :priority_models

      def initialize(uri,
                     priority_models: self.class.default_priority_models, exclude_self: false)
        @uri = uri
        @priority_models = priority_models
        @exclude_self = exclude_self
      end

      def descendant_and_self_uris
        partitioned = descendant_and_self_uris_partitioned
        partitioned[:priority] + partitioned[:other]
      end

      # returns a hash where key :priority is an array of all prioritized
      # type objects, key :other is an array of the rest.
      def descendant_and_self_uris_partitioned
        resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
        # GET could be slow if it's a big resource, we're using HEAD to avoid this problem,
        # but this causes more requests to Fedora.
        return partitioned_uris unless resource.head.rdf_source?

        add_self_to_partitioned_uris unless @exclude_self

        immediate_descendant_uris = rdf_graph.query(predicate: ::RDF::Vocab::LDP.contains).map { |descendant| descendant.object.to_s }
        immediate_descendant_uris.each do |descendant_uri|
          self.class.new(
            descendant_uri,
            priority_models: priority_models
          ).descendant_and_self_uris_partitioned.tap do |descendant_partitioned|
            partitioned_uris[:priority].concat descendant_partitioned[:priority]
            partitioned_uris[:other].concat descendant_partitioned[:other]
          end
        end
        partitioned_uris
      end

      protected

        def rdf_resource
          @rdf_resource ||= Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
        end

        def rdf_graph
          @rdf_graph ||= rdf_resource.graph
        end

        def partitioned_uris
          @partitioned_uris ||= {
            priority: [],
            other: []
          }
        end

        def rdf_graph_models
          rdf_graph.query(predicate: HAS_MODEL_PREDICATE).collect(&:object).collect do |rdf_object|
            rdf_object.to_s if rdf_object.literal?
          end.compact
        end

        def prioritized_object?
          priority_models.present? && (rdf_graph_models & priority_models).count > 0
        end

        def add_self_to_partitioned_uris
          if prioritized_object?
            partitioned_uris[:priority] << rdf_resource.subject
          else
            partitioned_uris[:other] << rdf_resource.subject
          end
        end
    end
  end
end
