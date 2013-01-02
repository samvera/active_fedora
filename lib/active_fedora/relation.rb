module ActiveFedora
  class Relation

    attr_reader :loaded
    alias :loaded? :loaded

    attr_accessor :limit_value, :where_values, :order_values
    
    def initialize(klass)
      @klass = klass
      @loaded = false
      self.where_values = []
      self.order_values = []
    end


    # Returns the first records that was found.
    #
    # @example
    #  Person.where(name_t: 'Jones').first
    #    => #<Person @id="foo:123" @name='Jones' ... >
    def first
      if loaded?
        @records.first
      else
        @first ||= limit(1).to_a[0]
      end
    end

    # Limits the number of returned records to the value specified
    #
    # @option [Integer] value the number of records to return
    #
    # @example
    #  Person.where(name_t: 'Jones').limit(10)
    #    => [#<Person @id="foo:123" @name='Jones'>, #<Person @id="foo:125" @name='Jones'>, ...]
    def limit(value)
      relation = clone
      relation.limit_value = value
      relation
    end

    # Limits the returned records to those that match the provided search conditions
    #
    # @option [Hash] opts a hash of solr conditions
    #
    # @example
    #  Person.where(name_t: 'Mario', occupation_s: 'Plumber')
    #    => [#<Person @id="foo:123" @name='Mario'>, #<Person @id="foo:125" @name='Mario'>, ...]
    def where(opts)
      return self if opts.blank?

      relation = clone
      relation.where_values = opts
      relation
    end

    # Order the returned records by the field and direction provided
    #
    # @option [Array<String>] args a list of fields and directions to sort by 
    #
    # @example
    #  Person.where(occupation_s: 'Plumber').order('name_t desc', 'color_t asc')
    #    => [#<Person @id="foo:123" @name='Luigi'>, #<Person @id="foo:125" @name='Mario'>, ...]
    def order(*args)
      return self if args.blank?

      relation = clone
      relation.order_values += args.flatten
      relation
    end
    

    def to_a
      return @records if loaded?
      args = {:cast=>true}
      args[:rows] = @limit_value if @limit_value
      args[:sort] = @order_values if @order_values
      
      @records = @klass.find(@where_values.present? ? @where_values : :all, args)
      @records
    end

    def ==(other)
      case other
      when Relation
        other.to_sql == to_sql
      when Array
        to_a == other
      end
    end

    def inspect
      to_a.inspect
    end
    
  end
end
