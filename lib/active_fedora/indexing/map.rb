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

    def dup
      self.class.new(to_hash)
    end

    def merge(new_hash)
      self.class.new(to_hash.merge(new_hash))
    end

    def to_hash
      @hash.deep_dup
    end

    # this enables a cleaner API for solr integration
    class IndexObject
      attr_accessor :data_type, :behaviors, :term
      attr_reader :key

      def initialize(name, behaviors: [], &_block)
        @behaviors = behaviors
        @data_type = :string
        @key = name
        yield self if block_given?
      end

      def as(*args)
        @term = args.last.is_a?(Hash) ? args.pop : {}
        @behaviors = args
      end

      def type(sym)
        @data_type = sym
      end

      def dup
        self.class.new(@key) do |idx|
          idx.behaviors = @behaviors.dup
        end
      end
    end
  end
end
