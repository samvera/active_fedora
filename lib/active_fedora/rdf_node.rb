module ActiveFedora
  module RdfNode
    extend ActiveSupport::Concern

    ##
    # Get the subject for this rdf object
    def rdf_subject
      @subject ||= begin
        s = self.class.rdf_subject.call(self)
        s &&= RDF::URI.new(s) if s.is_a? String
        s
      end
    end   

    def reset_rdf_subject!
      @subject = nil
    end

    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def get_values(subject, predicate)

      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      return TermProxy.new(self, subject, predicate)
    end


    def target_class(predicate)
      _, conf = self.class.config_for_predicate(predicate)
      class_name = conf[:class_name]
      return nil unless class_name
      self.class.const_get(class_name.to_sym)
    end

    # if there are any existing statements with this predicate, replace them
    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph

    def set_value(subject, predicate, values)
      
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI

      delete_predicate(subject, predicate)

      Array(values).each do |arg|
        arg = arg.to_s if arg.kind_of? RDF::Literal
        next if arg.kind_of?(String) && arg.empty?

        # If arg is a b-node, then copy it's statements onto the parent graph
        arg = merge_subgraph(arg) if arg.respond_to? :graph
        graph.insert([subject, predicate, arg])
      end

      return TermProxy.new(self, subject, predicate)
    end

 
    def delete_predicate(subject, predicate, values = nil)
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI

      if values.nil?
        query = RDF::Query.new do
          pattern [subject, predicate, :value]
        end

        query.execute(graph).each do |solution|
          graph.delete [subject, predicate, solution.value]
        end
      else
        Array(values).each do |v|
          graph.delete [subject, predicate, v]
        end
      end

    end

    # append a value 
    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def append(subject, predicate, args)
      graph.insert([subject, predicate, args])
      TermProxy.new(self, subject, predicate)
    end


    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def find_predicate(term)
      term = self.class.config[term.to_sym]
      term ? term[:predicate] : nil
    end

    def query subject, predicate, &block
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      
      q = RDF::Query.new do
        pattern [subject, predicate, :value]
      end

      q.execute(graph, &block)
    end

    def method_missing(name, *args)
      if (md = /^([^=]+)=$/.match(name.to_s)) && pred = find_predicate(md[1])
        set_value(rdf_subject, pred, *args)  
      elsif pred = find_predicate(name)
        klass = target_class(pred)
        if klass
          # return an array of klass.new from each of the values
          query(rdf_subject, pred).map do |solution|
            klass.new(graph, solution.value)
          end
        else
          get_values(rdf_subject, pred)
        end
      else 
        super
      end
    rescue ActiveFedora::UnregisteredPredicateError
      super
    end

    private
    # If arg is a b-node, then copy it's statements onto the parent graph
    def merge_subgraph(rdf_object)
      rdf_object.graph.statements.each do |s|
        graph.insert(s)
      end
      # Return the arg to point at the new b-node
      rdf_object.rdf_subject
    end

    class Builder
      def initialize(parent)
        @parent = parent
      end

      def build(&block)
        yield self
      end

      def method_missing(name, *args, &block)
        args = args.first if args.respond_to? :first
        raise "mapping must specify RDF vocabulary as :in argument" unless args.has_key? :in
        vocab = args[:in]
        field = args.fetch(:to, name).to_sym
        class_name = args[:class_name]
        raise "Vocabulary '#{vocab.inspect}' does not define property '#{field.inspect}'" unless vocab.respond_to? field
        indexing = false
        if block_given?
          # needed for solrizer integration
          indexing = true
          iobj = IndexObject.new
          yield iobj
          data_type = iobj.data_type
          behaviors = iobj.behaviors
        end
        @parent.config[name] = {:predicate => vocab.send(field) } 
        # stuff data_type and behaviors in there for to_solr support
        if indexing
          @parent.config[name][:type] = data_type
          @parent.config[name][:behaviors] = behaviors
        end
        @parent.config[name][:class_name] = class_name if class_name
      end

      # this enables a cleaner API for solr integration
      class IndexObject
        attr_accessor :data_type, :behaviors
        def initialize
          @behaviors = [:searchable]
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

    class TermProxy

      attr_reader :graph, :subject, :predicate
      delegate :class, :to_s, :==, :kind_of?, :each, :map, :empty?, :as_json, :is_a?, :to => :values

      def initialize(graph, subject, predicate)
        @graph = graph

        @subject = subject
        @predicate = predicate
      end

      def <<(*values)
        values.each { |value| graph.append(subject, predicate, value) }
        values
      end

      def delete(*values)
        values.each do |value| 
          graph.delete_predicate(subject, predicate, value)
        end

        values
      end

      def values
        values = []

        graph.query(subject, predicate).each do |solution|
          v = solution.value
          v = v.to_s if v.is_a? RDF::Literal
          values << v
        end

        values
      end
      
      def method_missing(method, *args, &block)
        if values.respond_to? method
          values.send(method, *args, &block)
        else
          super
        end
      end
    end
    module ClassMethods
      def config
        @config ||= {}
      end

      def map_predicates(&block)
        builder = Builder.new(self)
        builder.build &block
      end

      def rdf_type(uri_or_string)
        uri = RDF::URI.new(uri_or_string) unless uri_or_string.kind_of? RDF::URI
        self.config[:type] = {predicate: RDF.type}
        self.config[:rdf_type] = uri
      end

      def config_for_predicate(predicate)
        config.each do |term, value|
          return term, value if value[:predicate] == predicate
        end
        return nil
      end

      ##
      # Register a ruby block that evaluates to the subject of the graph
      # By default, the block returns the current object's pid
      # @yield [ds] 'ds' is the datastream instance
      def rdf_subject &block
        if block_given?
           return @subject_block = block
        end

        # Create a B-node if they don't supply the rdf_subject
        @subject_block ||= lambda { |ds| RDF::Node.new }
      end

    end
  end
end

