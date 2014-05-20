module ActiveFedora
  module QueryMethods # :nodoc:

    def extending_values
      @values[:extending] || []
    end

    def extending_values=(values)
      raise ImmutableRelation if @loaded
      @values[:extending] = values
    end

    def where_values
      @values[:where] ||= []
    end

    def where_values=(values)
      raise ImmutableRelation if @loaded
      @values[:where] = values
    end   

    def order_values
      @values[:order] || []
    end

    def order_values=(values)
      raise ImmutableRelation if @loaded
      @values[:order] = values
    end   

    def limit_value
      @values[:limit]
    end

    def limit_value=(value)
      raise ImmutableRelation if @loaded
      @values[:limit] = value
    end   

    def offset_value
      @values[:offset]
    end

    def offset_value=(value)
      raise ImmutableRelation if loaded?
      @values[:offset] = value
    end   

    # Limits the returned records to those that match the provided search conditions
    #
    # @option [Hash] opts a hash of solr conditions
    #
    # @example
    #  Person.where(name_t: 'Mario', occupation_s: 'Plumber')
    #    => [#<Person @id="foo:123" @name='Mario'>, #<Person @id="foo:125" @name='Mario'>, ...]
    def where(values)
      spawn.where!(values)
    end

    def where!(values)
      self.where_values += build_where(values)
      self
    end

    def build_where(values)
      return [] if values.blank?
      case values
      when Hash
        [create_query_from_hash(values)]
      when String
        ["(#{values})"]
      else
        [values]
      end
    end

    # Order the returned records by the field and direction provided
    #
    # @option [Array<String>] args a list of fields and directions to sort by 
    #
    # @example
    #  Person.where(occupation_s: 'Plumber').order('name_t desc', 'color_t asc')
    #    => [#<Person @id="foo:123" @name='Luigi'>, #<Person @id="foo:125" @name='Mario'>, ...]
    def order(*args)
      spawn.order!(args)
    end

    def order!(*args)
      self.order_values += args.flatten
      self
    end

    # Limits the number of returned records to the value specified
    #
    # @option [Integer] value the number of records to return
    #
    # @example
    #  Person.where(name_t: 'Jones').limit(10)
    #    => [#<Person @id="foo:123" @name='Jones'>, #<Person @id="foo:125" @name='Jones'>, ...]
    def limit(value)
      spawn.limit!(value)
    end

    def limit!(value)
      self.limit_value = value
      self
    end

    # Start the returned records at an offset position.
    # Useful for paginated results
    #
    # @option [Integer] value the number of records offset
    #
    # @example
    #  Person.where(name_t: 'Jones').offset(1000)
    #    => [#<Person @id="foo:123" @name='Jones'>, #<Person @id="foo:125" @name='Jones'>, ...]
    def offset(value)
      spawn.offset!(value)
    end

    def offset!(value)
      self.offset_value = value
      self
    end

    def none! # :nodoc:
      extending!(NullRelation)
    end

    def extending!(*modules, &block) # :nodoc:
      modules << Module.new(&block) if block
      modules.flatten!

      self.extending_values += modules
      extend(*extending_values) if extending_values.any?

      self
    end

    def select
      to_a.select { |*block_args| yield(*block_args) }
    end
  end
end
