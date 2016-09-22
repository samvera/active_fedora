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
            return false unless record.save(validate: validate)
          end
        end
        owner[reflection.foreign_key] ||= []
        owner[reflection.foreign_key] += [record.id]

        # Only if they've explicitly stated the inverse in the options
        if reflection.options[:inverse_of]
          inverse = reflection.inverse_of
          if owner.new_record?
            ActiveFedora::Base.logger.warn("has_and_belongs_to_many #{reflection.inspect} is cowardly refusing to insert the inverse relationship into #{record}, because #{owner} is not persisted yet.")
          elsif inverse.has_and_belongs_to_many?
            record[inverse.foreign_key] ||= []
            record[inverse.foreign_key] += [owner.id]
            record.save
          end
        end

        true
      end

      def concat_records(*records)
        result = true

        records.flatten.each do |record|
          raise_on_type_mismatch!(record)
          add_to_target(record) do |_r|
            result &&= insert_record(record)
          end
        end

        result && records
      end

      # In a HABTM, just look in the RDF, no need to run a count query from solr.
      def count(_options = {})
        owner[reflection.foreign_key].size
      end

      delegate :first, to: :load_target

      protected

        def count_records
          load_target.size
        end

        def delete_records(records, _method)
          records.each do |r|
            owner[reflection.foreign_key] -= [r.id]
            inverse = @reflection.inverse_of
            next unless inverse
            r[inverse.foreign_key] -= [owner.id] if inverse.has_and_belongs_to_many?
            r.association(inverse.name).reset
            r.save
          end
          @owner.save! unless @owner.new_record? || @owner.destroyed?
        end

      private

        def stale_state
          owner[reflection.foreign_key]
        end

        def find_target
          ids = owner[reflection.foreign_key]
          return [] if ids.blank?
          ActiveFedora::Base.find(ids)
        end
    end
  end
end
