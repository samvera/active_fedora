require 'forwardable'
module ActiveFedora::Indexing
  # This is a description of how properties should map to indexing strategies
  #  e.g. 'creator_name' => <IndexObject behaviors=[:stored_searchable, :facetable]>
  class Map
    extend Forwardable
    def_delegators :@hash, :[], :[]=, :each, :keys

    def initialize(hash = {})
      @hash = hash
    end

    # this enables a cleaner API for solr integration
    class IndexObject
      attr_accessor :data_type, :behaviors

      def initialize(&block)
        @behaviors = []
        @data_type = :string
        yield self if block_given?
      end

      def as(*args)
        @behaviors = args
      end

      def type(sym)
        @data_type = sym
      end

      def defaults
        :noop
      end
    end
  end
end
