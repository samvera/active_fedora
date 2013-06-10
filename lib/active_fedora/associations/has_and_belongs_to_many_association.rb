module ActiveFedora
  # = Active Fedora Has And Belongs To Many Association
  module Associations
    class HasAndBelongsToManyAssociation < AssociationCollection #:nodoc:
      def initialize(owner, reflection)
        super
      end

      def find_target
          pids = @owner.ids_for_outbound(@reflection.options[:property])
          return [] if pids.empty?
          query = ActiveFedora::SolrService.construct_query_for_pids(pids)
          solr_result = SolrService.query(query)
          return ActiveFedora::SolrService.reify_solr_results(solr_result)
      end

      protected

        def count_records
          load_target.size
        end

        def insert_record(record, force = true, validate = true)
          if record.new_record?
            if force
              record.save!
            else
              return false unless record.save(:validate => validate)
            end
          end

          ### TODO save relationship
          @owner.add_relationship(@reflection.options[:property], record)

          if @owner.new_record? and @reflection.options[:inverse_of]
            logger.warn("has_and_belongs_to_many #{@reflection.inspect} is cowardly refusing to insert the inverse relationship into #{record}, because #{@owner} is not persisted yet.")
          elsif @reflection.options[:inverse_of]
            record.add_relationship(@reflection.options[:inverse_of], @owner)
            record.save
          end

          return true
        end

        def delete_records(records)
          records.each do |r| 
            @owner.remove_relationship(@reflection.options[:property], r)
            
            if (@reflection.options[:inverse_of])
              r.remove_relationship(@reflection.options[:inverse_of], @owner)
              # It looks like inverse_of points at a predicate, not at a relationship name,
              # which is what we should have done. Now we need a way to look up the
              # reflection by predicate
              name = r.class.reflection_name_for_predicate(@reflection.options[:inverse_of])
              r.send(name).reset
              r.save
            end
          end
        end

    end
  end
end
