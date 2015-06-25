module ActiveFedora::RDF
  # Transient class that represents a field that we send to solr.
  # It might be possible for two properties to share a single field map entry if they use the same solr key.
  # @attribute [Symbol] type the data type hint for Solrizer
  # @attribute [Array] behaviors the indexing hints such as :stored_searchable or :symbol
  # @attribute [Array] values the actual values that get sent to solr
  class FieldMapEntry

    attr_accessor :type, :behaviors, :values

    def initialize
      @behaviors = []
      @values = []
    end

    # Merges any existing values for solr fields with new, incoming values and ensures that resulting values are unique.
    # @param [Symbol] type the data type for the field such as :string, :date, :integer
    # @param [Array] behaviors Solrizer's behaviors for indexing such as :stored_searhable, :symbol
    # @param [Array] values existing values for the solr field
    def merge!(type, behaviors, values)
      self.type ||= type
      self.behaviors += behaviors
      self.behaviors.uniq!
      self.values += values
    end

  end
end
