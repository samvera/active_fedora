module ActiveFedora
  module Associations
    class BelongsToAssociation < SingularAssociation #:nodoc:

      def replace(record)
        if record
          raise_on_type_mismatch(record)
          # update_counters(record)
          replace_keys(record)
          set_inverse_instance(record)
          @updated = true
        else
          # decrement_counters
          remove_keys
        end

        self.target = record
      end

      def reset
        super
        @updated = false
      end

      def updated?
        @updated
      end

      private

        def replace_keys(record)
          owner[reflection.foreign_key] = record.id
        end

        def remove_keys
          owner[reflection.foreign_key] = nil
        end

        # Constructs a query that checks solr for the correct id & class_name combination
        def construct_query(ids)
          # Some descendants of ActiveFedora::Base are anonymous classes. They don't have names. Filter them out.
          candidate_classes = klass.descendants.select {|d| d.name }
          candidate_classes += [klass] unless klass == ActiveFedora::Base
          model_pairs = candidate_classes.inject([]) { |arr, klass| arr << [:has_model, klass.to_class_uri]; arr }
          '(' + ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids) + ') AND (' +
              ActiveFedora::SolrQueryBuilder.construct_query_for_rel(model_pairs, 'OR') + ')'
        end

        def foreign_key_present?
          owner[reflection.foreign_key]
        end

        # belongs_to is not invertible (unless we implement has_one, then make an exception here)
        def invertible_for?(_)
          false
        end

        def stale_state
          owner[reflection.foreign_key]
        end
    end
  end
end
