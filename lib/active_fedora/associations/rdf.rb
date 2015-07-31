module ActiveFedora
  module Associations
    class RDF < SingularAssociation #:nodoc:

      def replace(values)
        ids = Array(values).reject(&:blank?)
        raise "can't modify frozen #{owner.class}" if owner.frozen?
        destroy
        ids.each do |id|
          uri = ::RDF::URI(ActiveFedora::Base.id_to_uri(id))
          owner.resource.insert [owner.rdf_subject, reflection.predicate, uri]
        end
        owner.send(:attribute_will_change!, reflection.name)
      end

      def reader
        filtered_results.map { |val| ActiveFedora::Base.uri_to_id(val) }
      end

      def destroy
        filtered_results.each do |candidate|
          owner.resource.delete([owner.rdf_subject, reflection.predicate, candidate])
        end
      end

      private

      # @return [Array<RDF::URI>] the rdf results filtered to objects that match the specified class_name consraint
      def filtered_results
        if filtering_required?
          filter_by_class(rdf_uris)
        else
          rdf_uris
        end
      end

      def filtering_required?
        return false if reflection.klass == ActiveFedora::Base
        reflections_with_same_predicate.count > 1
      end

      # Count the number of reflections that have the same predicate as the reflection
      # for this association.
      def reflections_with_same_predicate
        owner.class.outgoing_reflections.select { |k, v| v.options[:predicate] == reflection.predicate }
      end

      # @return [Array<RDF::URI>]
      def rdf_uris
        rdf_query.map(&:object)
      end

      # @return [Array<RDF::Statement>]
      def rdf_query
        owner.resource.query(subject: owner.rdf_subject, predicate: reflection.predicate).enum_statement
      end

      # @return [Array<RDF::URI>]
      def filter_by_class(candidate_uris)
        return [] if candidate_uris.empty?
        ids = candidate_uris.map {|uri| ActiveFedora::Base.uri_to_id(uri) }
        results = ActiveFedora::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids), rows: 10000)

        docs = results.select do |result|
          ActiveFedora::QueryResultBuilder.classes_from_solr_document(result).any? { |klass|
            class_ancestors(klass).include? reflection.klass
          }
        end

        docs.map {|doc| ::RDF::URI.new(ActiveFedora::Base.id_to_uri(doc['id']))}
      end

      ##
      # Returns a list of all the ancestor classes up to ActiveFedora::Base including the class itself
      # @param [Class] klass
      # @return [Array<Class>]
      # @example
      #   class Car < ActiveFedora::Base; end
      #   class SuperCar < Car; end
      #   class_ancestors(SuperCar)
      #   # => [SuperCar, Car, ActiveFedora::Base]
      def class_ancestors(klass)
        klass.ancestors.select {|k| k.instance_of?(Class) } - [Object, BasicObject]
      end



    end
  end
end

