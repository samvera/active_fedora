module ActiveFedora::RDF
  # Transient class that maps solr field names, without their suffixes, to the values and behaviors that
  # are used to transforming them for insertion into the solr document.
  # It partially extends Ruby's Hash class, similar to the way ActiveFedora::Indexing::Map does,
  # but only with selected methods as outlined in def_delegators.
  class FieldMap
    extend Forwardable

    def_delegators :@hash, :[], :[]=, :each, :keys

    def initialize(hash = {}, &_block)
      @hash = hash
      yield self if block_given?
    end

    # Inserts each solr field map configuration into the FieldMap class
    # @param [Symbol] name the name of the property on the object that we're indexing
    # @param [ActiveFedora::Indexing::Map::IndexObject] index_field_config describes how the object should be indexed
    # @param [ActiveFedora::Base] object the object to be indexed into Solr
    def insert(name, index_field_config, object)
      self[index_field_config.key.to_s] ||= FieldMapEntry.new
      PolymorphicBuilder.new(self[index_field_config.key.to_s], index_field_config, object, name).build
    end

    # Supports assigning the delegate class that calls .build to insert the fields into the solr document.
    # @attr [Object] entry instance of ActiveFedora::RDF::FieldMapEntry which will contain the values of the solr field
    # @attr [Object] index_field_config an instance of ActiveFedora::Indexing::Map::IndexObject
    # @attr [Object] object the instance of ActiveFedora::Base which is being indexed into Solr
    # @attr [Symbol] name the name of the property on the object that we're indexing
    class PolymorphicBuilder
      attr_accessor :entry, :index_field_config, :object, :name

      def initialize(entry, index_field_config, object, name)
        @entry              = entry
        @index_field_config = index_field_config
        @object             = object
        @name               = name
        self
      end

      def build
        delegate_class.new(entry, index_field_config, object, name).build
      end

      private

        def delegate_class
          kind_of_af_base? ? ResourceBuilder : PropertyBuilder
        end

        def kind_of_af_base?
          config = properties[name.to_s]
          config && config[:class_name] && config[:class_name] < ActiveFedora::Base
        end

        def properties
          object.class.properties
        end
    end

    # Abstract class that implements the PolymorphicBuilder interface and is used for
    # for building FieldMap entries. You can extend this object to create your own
    # builder for creating the values in your solr fields.
    class Builder < PolymorphicBuilder
      def build
        type = index_field_config.data_type
        behaviors = index_field_config.behaviors
        return unless type && behaviors
        entry.merge!(type, behaviors, find_values)
      end
    end

    # Builds a FieldMap entry for a resource such as an ActiveFedora::Base object and returns the uri as the value
    # unless :using has been set as an option to the index.as block on the property in question. In that case, the
    # symbol assigned to :using will used as the value.
    class ResourceBuilder < Builder
      def find_values
        object.send(name).map(&index_field_config.term.fetch(:using, :uri))
      end
    end

    # Builds a FieldMap entry for a rdf property and returns the values
    class PropertyBuilder < Builder
      def find_values
        Array(object.send(name))
      end
    end
  end
end
