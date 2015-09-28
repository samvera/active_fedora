module ActiveFedora
  ##
  # Used as an access method for associations on a model, given some
  # reflections.
  class AssociationHash
    def initialize (model, reflections)
      @base = model
      @reflections = reflections
    end

    def [] (name)
      association(name).reader if association(name)
    end

    def []= (name, object)
      association(name).writer(object) if association(name)
    end

    def association(name)
      # Check to see if the key exists before casting to a symbol, because symbols
      # are not garbage collected in earlier versions of Ruby
      @base.association(name.to_sym) if key?(name)
    end

    def reflections
      @reflections
    end

    def merge(other_hash)
      Merged.new(self, other_hash)
    end

    def each
      keys.each do |k|
        yield k, self[k]
      end
    end

    def keys
      reflections.keys
    end

    # Check that the key exists with indifferent access (symbol or string) in a
    # manner that avoids generating extra symbols. Symbols are not garbage collected
    # in earlier versions of ruby.
    def key?(key)
      keys.include?(key) || keys.map(&:to_s).include?(key)
    end

    def values
      keys.map { |k| self[k] }
    end

    def has_key?(key)
      keys.include?(key)
    end

    def size
      keys.size
    end

    def empty?
      reflections.empty?
    end

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

    def select
      keys.each_with_object({}) do |k, h|
        val = self[k]
        h[k] = val if yield k, val
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
      @second = second
    end

    def [] (name)
      first[name] || second[name]
    end

    def []= (name)
      raise NotImplementedError "Unable to set properties on a merged association hash"
    end

    def keys
      first.keys + second.keys
    end
  end
end
