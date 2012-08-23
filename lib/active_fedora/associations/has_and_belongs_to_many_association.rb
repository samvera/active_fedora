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
          if (@reflection.options[:inverse_of])
            record.add_relationship(@reflection.options[:inverse_of], @owner)
          end
          record.save
          return true
        end

        def delete_records(records)
          records.each do |r| 
            r.remove_relationship(@reflection.options[:property], @owner)
          end
        end
    end
  end
end
