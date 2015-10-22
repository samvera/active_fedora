module ActiveFedora
  class Relation
    class HashMerger # :nodoc:
    end

    class Merger # :nodoc:
      attr_reader :relation, :values, :other

      def initialize(relation, other)
        @relation = relation
        @values   = other.values
        @other    = other
      end

      def merge
        # TODO: merge order
        relation.where_values += other.where_values
        relation
      end
    end
  end
end
