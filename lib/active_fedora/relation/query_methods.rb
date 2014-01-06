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
      @values[:where] || {}
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
  end
end
