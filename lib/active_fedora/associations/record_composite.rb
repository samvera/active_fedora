module ActiveFedora::Associations
  ##
  # A Composite for records - currently only supports delete interface.
  # The goal is to push commands down to the containing records.
  class RecordComposite
    attr_reader :records
    include Enumerable
    def initialize(records:)
      @records = records
    end

    def each
      records.each do |record|
        yield record
      end
    end

    def delete
      each(&:delete)
    end
    ##
    # A Repository which returns a composite from #find instead of a single
    # record. Delegates find to a base repository.
    class Repository
      attr_reader :base_repository
      delegate :translate_uri_to_id, to: :base_repository
      def initialize(base_repository:)
        @base_repository = base_repository
      end

      def find(ids)
        records = ids.map do |id|
          base_repository.find(id)
        end
        RecordComposite.new(records: records)
      end
    end
  end
end
