module ActiveFedora::RDF
  # Transient class that represents a field that we send to solr.
  # It might be possible for two properties to share a single field map entry if they use the same solr key.
  # @attribute [Symbol] type the data type hint for Solrizer
  # @attribute [Array] behaviors the indexing hints such as :stored_searchable or :symbol
  # @!attribute [w] values the raw values
  class FieldMapEntry
    attr_accessor :type, :behaviors
    attr_writer :values

    def initialize
      @behaviors = []
      @values = []
    end

    # Merges any existing values for solr fields with new, incoming values and ensures that resulting values are unique.
    # @param [Symbol] type the data type for the field such as :string, :date, :integer
    # @param [Array] behaviors Solrizer's behaviors for indexing such as :stored_searhable, :symbol
    # @param [Array] new_values values to append into the existing solr field
    def merge!(type, behaviors, new_values)
      self.type ||= type
      self.behaviors += behaviors
      self.behaviors.uniq!
      self.values += new_values
    end

    # @return [Array] the actual values that get sent to solr
    def values
      @values.map do |value|
        ValueCaster.new(value).value
      end
    end
  end
end
