module ActiveFedora
  module Indexing
    # Finds all descendent URIs of a given repo URI (usually the base URI).
    #
    # This is a slow and non-performant thing to do, we need to fetch every single
    # object from the repo.
    #
    # The DescendantFetcher is also capable of partitioning the URIs into "priority" URIs
    # that will be first in the returned list. These prioritized URIs belong to objects
    # with certain hasModel models. This feature is used in some samvera apps that need to
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

      # @return [Array<String>] uris starting with priority models
      def descendant_and_self_uris
        partitioned = descendant_and_self_uris_partitioned
        partitioned[:priority] + partitioned[:other]
      end

      # returns a hash where key :priority is an array of all prioritized
      # type objects, key :other is an array of the rest.
      # @return [Hash<String, Array<String>>] uris sorted into :priority and :other
      def descendant_and_self_uris_partitioned
        model_partitioned = descendant_and_self_uris_partitioned_by_model
        { priority: model_partitioned.slice(*priority_models).values.flatten,
          other: model_partitioned.slice(*(model_partitioned.keys - priority_models)).values.flatten }
      end

      # Returns a hash where keys are model names
      # This is useful if you need to action on certain models and want finer grainularity than priority/other
      # @return [Hash<String, Array<String>>] uris sorted by model names
      def descendant_and_self_uris_partitioned_by_model
        # GET could be slow if it's a big resource, we're using HEAD to avoid this problem,
        # but this causes more requests to Fedora.
        return partitioned_uris unless rdf_resource.head.rdf_source?

        add_self_to_partitioned_uris unless @exclude_self

        rdf_graph.query({ predicate: ::RDF::Vocab::LDP.contains }).each_object do |uri|
          descendant_uri = uri.to_s
          self.class.new(
            descendant_uri,
            priority_models: priority_models
          ).descendant_and_self_uris_partitioned_by_model.tap do |descendant_partitioned|
            descendant_partitioned.keys.each do |k|
              partitioned_uris[k] ||= []
              partitioned_uris[k].concat descendant_partitioned[k]
            end
          end
        end
        partitioned_uris
      end

      protected

        def rdf_resource
          @rdf_resource ||= Ldp::Resource::RdfSource.new(ActiveFedora.fedora.build_ntriples_connection, uri)
        end

        def rdf_graph
          @rdf_graph ||= rdf_resource.graph
        end

        def partitioned_uris
          @partitioned_uris ||= {}
        end

        def add_self_to_partitioned_uris
          rdf_graph.query({ predicate: HAS_MODEL_PREDICATE }).each_object do |model|
            next unless model.literal?

            partitioned_uris[model.to_s] ||= []
            partitioned_uris[model.to_s] << rdf_resource.subject
          end
        end
    end
  end
end
