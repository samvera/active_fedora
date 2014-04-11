module ActiveFedora
  module Rdf
    class NodeConfig
      attr_accessor :predicate, :term, :class_name, :type, :behaviors, :multivalue

      def initialize(term, predicate, args={})
        self.term = term
        self.predicate = predicate
        self.class_name = args.delete(:class_name)
        self.multivalue = args.delete(:multivalue) { true } 
        raise ArgumentError, "Invalid arguments for Rdf Node configuration: #{args} on #{predicate}" unless args.empty?
      end

      def [](value)
        value = value.to_sym
        self.respond_to?(value) ? self.send(value) : nil
      end

      def class_name
        if @class_name.kind_of?(String)
          begin
            new_class = @class_name.constantize
            @class_name = new_class
          rescue NameError
          end
        end
        @class_name
      end

      def with_index (&block)
        # needed for solrizer integration
        iobj = IndexObject.new
        yield iobj
        self.type = iobj.data_type
        self.behaviors = iobj.behaviors
      end

      # this enables a cleaner API for solr integration
      class IndexObject
        attr_accessor :data_type, :behaviors
        def initialize
          @behaviors = []
          @data_type = :string
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
end
