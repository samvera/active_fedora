require 'forwardable'

module ActiveFedora
  class FilesHash
    extend Forwardable

    def initialize (model)
      @base = model
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
      @base.class.child_resource_reflections
    end

    def each
      keys.each do |k|
        yield k, self[k]
      end
    end

    def keys
      reflections.keys + @base.undeclared_files
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
end
