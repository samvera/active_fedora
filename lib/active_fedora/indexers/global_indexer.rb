module ActiveFedora::Indexers
  ##
  # Applies indexing hints to any given property, independent of what that
  # property
  class GlobalIndexer
    # @param [Array<Symbol>] index_types The indexing hints to use.
    def initialize(index_types = nil)
      @index_types = Array.wrap(index_types)
    end

    # The global indexer acts as both an indexer factory and an indexer, since
    # the property doesn't matter.
    def new(_property)
      self
    end

    # @param [ActiveFedora::Indexing::Map::IndexObject, #as] index_obj The indexing
    #   object to call #as on.
    def index(index_obj)
      index_obj.as(*index_types) unless index_types.empty?
    end

    private

      attr_reader :index_types
  end
end
