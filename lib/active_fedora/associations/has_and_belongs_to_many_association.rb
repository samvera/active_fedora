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

        if @owner.new_record? and @reflection.options[:inverse_of]
          ActiveFedora::Base.logger.warn("has_and_belongs_to_many #{@reflection.inspect} is cowardly refusing to insert the inverse relationship into #{record}, because #{@owner} is not persisted yet.") if ActiveFedora::Base.logger
        elsif @reflection.options[:inverse_of]
          inverse = @reflection.inverse_of
          record[@reflection.inverse_of.foreign_key] = [owner.id]
          record.save
        end

        return true
      end


      def find_target
          page_size = @reflection.options[:solr_page_size]
          page_size ||= 200
          pids = owner[reflection.foreign_key]
          return [] unless pids
          solr_result = []
          0.step(pids.size,page_size) do |startIdx|
            query = ActiveFedora::SolrService.construct_query_for_pids(pids.slice(startIdx,page_size))
            solr_result += ActiveFedora::SolrService.query(query, rows: page_size)
          end
          return ActiveFedora::SolrService.reify_solr_results(solr_result)
      end

      # In a HABTM, just look in the rels-ext, no need to run a count query from solr.
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
            owner[reflection.foreign_key].delete(r.id)
            
            if (@reflection.options[:inverse_of])
              inverse = @reflection.inverse_of
              r[inverse.foreign_key].delete(@owner.id)
              r.association(inverse.name).reset
              r.save
            end
          end
          @owner.save! unless @owner.new_record?
        end

    end
  end
end
