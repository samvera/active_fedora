module ActiveFedora
  module Associations
    class BelongsToAssociation < SingularAssociation #:nodoc:

      def replace(record)
        raise_on_type_mismatch(record) if record

        replace_keys(record)

        @updated = true if record

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
          if record
            owner[reflection.foreign_key] = record.uri
          else
            owner[reflection.foreign_key] = nil
          end
        end

        def construct_query pid
          if klass != ActiveFedora::Base
            clauses = {}  
            clauses[:has_model] = klass.to_class_uri
            query = ActiveFedora::SolrService.construct_query_for_rel(clauses) + " AND (" + ActiveFedora::SolrService.construct_query_for_pids([pid]) + ")"
          else
            query = ActiveFedora::SolrService.construct_query_for_pids(pid)
          end
        end

        def remove_matching_property_relationship
          # puts "Results: #{@owner.graph.query([@owner.uri,  predicate, nil])}"
          ids = @owner.send :"#{@reflection.name}_id"
          # ids = @owner.ids_for_outbound(@reflection.options[:property])
          # puts "new #{new_ids.inspect} vs old #{ids.inspect}"
          ids.each do |id|
            result = SolrService.query(ActiveFedora::SolrService.construct_query_for_pids([id]))
            hit = ActiveFedora::SolrService.reify_solr_results(result).first
            # We remove_relationship on subjects that match the same class, or if the subject is nil 
            if hit.class == klass || hit.nil?
              @owner.remove_relationship(@reflection.options[:property], hit)
            end
          end
        end

        def foreign_key_present?
          owner[reflection.foreign_key]
        end

        def stale_state
          owner[reflection.foreign_key]
        end
    end
  end
end
