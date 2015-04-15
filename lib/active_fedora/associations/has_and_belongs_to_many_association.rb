module ActiveFedora
  # = Active Fedora Has And Belongs To Many Association
  module Associations
    class HasAndBelongsToManyAssociation < CollectionAssociation #:nodoc:
      def initialize(owner, reflection)
        super
      end

      def insert_record(record, force = true, validate = true)
        if record.new_record?
          if force
            record.save!
          else
            return false unless record.save(:validate => validate)
          end
        end

        owner[reflection.foreign_key] ||= []
        owner[reflection.foreign_key] += [record.id]

        # Only if they've explicitly stated the inverse in the options
        if reflection.options[:inverse_of]
          inverse = reflection.inverse_of
          if owner.new_record?
            ActiveFedora::Base.logger.warn("has_and_belongs_to_many #{reflection.inspect} is cowardly refusing to insert the inverse relationship into #{record}, because #{owner} is not persisted yet.") if ActiveFedora::Base.logger
          elsif inverse.has_and_belongs_to_many?
            record[inverse.foreign_key] ||= []
            record[inverse.foreign_key] += [owner.id]
            record.save
          end
        end

        return true
      end

      def concat_records(*records)
        result = true

        records.flatten.each do |record|
          raise_on_type_mismatch(record)
          add_to_target(record) do |r|
            result &&= insert_record(record)
          end
        end

        result && records
      end


      def find_target
        page_size = @reflection.options[:solr_page_size]
        page_size ||= 200
        ids = owner[reflection.foreign_key]
        return [] if ids.blank?
        solr_result = []
        0.step(ids.size,page_size) do |startIdx|
          query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids.slice(startIdx,page_size))
          solr_result += ActiveFedora::SolrService.query(query, rows: page_size)
        end
        return ActiveFedora::QueryResultBuilder.reify_solr_results(solr_result)
      end

      # In a HABTM, just look in the RDF, no need to run a count query from solr.
      def count(options = {})
        owner[reflection.foreign_key].size
      end

      def first
        load_target.first
      end

      protected

        def count_records
          load_target.size
        end

        def delete_records(records, method)
          records.each do |r|
            owner[reflection.foreign_key] -= [r.id]

            if inverse = @reflection.inverse_of
              r[inverse.foreign_key] -= [owner.id] if inverse.has_and_belongs_to_many?
              r.association(inverse.name).reset
              r.save
            end
          end
          unless @owner.new_record? || @owner.destroyed?
            @owner.save!
          end
        end

      private

        def stale_state
          owner[reflection.foreign_key]
        end

    end
  end
end
