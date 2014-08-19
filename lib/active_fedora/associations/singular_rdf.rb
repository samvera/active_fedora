module ActiveFedora
  module Associations
    class SingularRdf < SingularAssociation #:nodoc:

      def replace(value)
        destroy
        return unless value
        uri = ActiveFedora::Base.id_to_uri(value)
        owner.resource.insert [owner.rdf_subject, reflection.predicate, RDF::URI.new(uri)]
      end

      def reader
        val = owner.resource.query(subject: owner.rdf_subject, predicate: reflection.predicate).first
        return unless val
        ActiveFedora::Base.uri_to_id(val.object)
      end

      def destroy
        owner.resource.query([nil, reflection.predicate, nil]).each_statement do |statement|
          owner.resource.delete(statement)
        end
      end
    end
  end
end
