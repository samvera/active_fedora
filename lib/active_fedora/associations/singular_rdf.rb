module ActiveFedora
  module Associations
    class SingularRDF < RDF #:nodoc:
      def replace(value)
        super(Array(value))
      end

      def reader
        super.first
      end
    end
  end
end
