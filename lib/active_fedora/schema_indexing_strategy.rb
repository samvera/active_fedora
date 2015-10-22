module ActiveFedora
  ##
  # An extension strategy to also apply solr indexes for each property.
  # @note If how a field is indexed changes based on property, this would be a
  #   good place to define that.
  class SchemaIndexingStrategy
    # @param [#index] indexer The indexer to use
    def initialize(indexer = Indexers::NullIndexer.instance)
      @indexer = indexer
    end

    # @param [ActiveFedora::Base] object The object to apply the property to.
    # @param [ActiveTriples::Property, #name, #to_h] property The property to define.
    def apply(object, property)
      object.property property.name, property.to_h do |index|
        indexer.new(property).index(index)
      end
    end

    private

      attr_reader :indexer
  end
end
