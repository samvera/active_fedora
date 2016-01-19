module ActiveFedora
  ##
  # Used as an access method for associations on a model, given some
  # reflections.
  class AssociationHash
    attr_reader :base

    def initialize(model, reflections)
      @base = model
      @reflections = reflections
    end

    def [](name)
      association(name).reader if association(name)
    end

    def []=(name, object)
      association(name).writer(object) if association(name)
    end

    def association(name)
      # Check to see if the key exists before casting to a symbol, because symbols
      # are not garbage collected in earlier versions of Ruby
      base.association(name.to_sym) if key?(name)
    end

    attr_reader :reflections

    def merge(other_hash)
      Merged.new(self, other_hash)
    end

    def each
      keys.each do |k|
        yield k, self[k]
      end
    end

    delegate :keys, to: :reflections

    # Check that the key exists with indifferent access (symbol or string) in a
    # manner that avoids generating extra symbols. Symbols are not garbage collected
    # in earlier versions of ruby.
    def key?(key)
      keys.include?(key) || keys.map(&:to_s).include?(key)
    end
    alias include? key?
    alias has_key? key?

    def values
      keys.map { |k| self[k] }
    end

    delegate :size, to: :keys

    delegate :empty?, to: :reflections

    def each_value
      keys.each do |k|
        yield self[k]
      end
    end

    def changed
      select do |_, obj|
        obj.changed?
      end
    end

    # returns the loaded files for with the passed block returns true
    def select
      keys.each_with_object({}) do |k, h|
        if association(k).loaded?
          val = self[k]
          h[k] = val if yield k, val
        end
      end
    end

    def freeze
      keys.each do |name|
        association(name).reader.freeze if association(name).loaded?
      end
      super
    end
  end
  ##
  # Represents the result of merging two association hashes.
  # @note As the keys can come from multiple models, the attributes become
  # unwritable.
  class Merged < AssociationHash
    attr_reader :first, :second

    def initialize(first, second)
      @first = first
      @base = first.base
      @second = second
    end

    def [](name)
      first[name] || second[name]
    end

    def []=(_name)
      raise NotImplementedError, "Unable to set properties on a merged association hash."
    end

    def keys
      first.keys + second.keys
    end
  end
end
