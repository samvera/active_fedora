module ActiveFedora::Associations
  class FilterAssociation < ::ActiveFedora::Associations::CollectionAssociation
    # @param [Array] records a list of records to replace the current association with
    # @raise [ArgumentError] if one of the records doesn't match the prescribed condition
    def writer(records)
      records.each { |r| validate_assertion!(r) }
      existing_matching_records.each do |r|
        extending_from.delete(r)
      end
      extending_from.concat(records)
    end

    delegate :delete, to: :extending_from

    # @param [Array] records a list of records to append to the current association
    # @raise [ArgumentError] if one of the records doesn't match the prescribed condition
    def concat(records)
      records.flatten.each { |r| validate_assertion!(r) }
      extending_from.concat(records)
    end

    def ids_reader
      load_target
      super
    end

    def count_records
      ids_reader.length
    end

    private

      # target should never be cached as part of this objects state, because
      # extending_from.target could change and we want to reflect those changes
      def target
        find_target
      end

      def find_target?
        true
      end

      def find_target
        existing_matching_records
      end

      # We can't create an association scope on here until we can figure a way to
      # index/query the condition in Solr
      def association_scope
        nil
      end

      def existing_matching_records
        extending_from.reader.to_a.select do |r|
          validate_assertion(r)
        end
      end

      def extending_from
        owner.association(options.fetch(:extending_from))
      end

      def validate_assertion(record)
        record.send(options.fetch(:condition))
      end

      def validate_assertion!(record)
        raise ArgumentError, "#{record.class} with ID: #{record.id} was expected to #{options.fetch(:condition)}, but it was false" unless validate_assertion(record)
      end
  end
end
