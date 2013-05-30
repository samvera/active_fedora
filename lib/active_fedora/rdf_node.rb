module ActiveFedora
  module RdfNode
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :TermProxy

    # Mapping from URI to ruby class
    def self.rdf_registry
      @@rdf_registry ||= {}
    end


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

    # @param [RDF::URI] subject the base node to start the search from
    # @param [Symbol] term the term to get the values for
    def get_values(subject, term)
      options = config_for_term_or_uri(term)
      predicate = options[:predicate]
      TermProxy.new(self, subject, predicate, options)
    end

    def target_class(predicate)
      _, conf = self.class.config_for_predicate(predicate)
      class_name = conf[:class_name]
      return nil unless class_name
      ActiveFedora.class_from_string(class_name, self.class)
    end

    # if there are any existing statements with this predicate, replace them
    # @param [RDF::URI] subject  the subject to insert into the graph
    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    # @param [Array,#to_s] values  the value/values to insert into the graph
    def set_value(subject, predicate, values)
      options = config_for_term_or_uri(predicate)
      predicate = options[:predicate]
      values = Array(values)

      remove_existing_values(subject, predicate, values)

      values.each do |arg|
        if arg.respond_to?(:rdf_subject) # an RdfObject
          graph.insert([subject, predicate, arg.rdf_subject ])
        else
          arg = arg.to_s if arg.kind_of? RDF::Literal
          graph.insert([subject, predicate, arg])
        end
      end

      TermProxy.new(self, subject, predicate, options)
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
      options = config_for_term_or_uri(predicate)
      graph.insert([subject, predicate, args])
      TermProxy.new(self, subject, options[:predicate], options)
    end

    def config_for_term_or_uri(term)
      case term
      when RDF::URI
        self.class.config.each { |k, v| return v if v[:predicate] == term}
      else
        self.class.config[term.to_sym]
      end
    end

    # @param [Symbol, RDF::URI] term predicate  the predicate to insert into the graph
    def find_predicate(term)
      conf = config_for_term_or_uri(term)
      conf ? conf[:predicate] : nil
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
      elsif find_predicate(name)
          get_values(rdf_subject, name)
      else 
        super
      end
    rescue ActiveFedora::UnregisteredPredicateError
      super
    end

    private

    def remove_existing_values(subject, predicate, values)
      if values.any? { |x| x.respond_to?(:rdf_subject)}
        values.each do |arg|
          if arg.respond_to?(:rdf_subject) # an RdfObject
            # can't just delete_predicate, have to delete the predicate with the class
            values_to_delete = find_values_with_class(subject, predicate, arg.class.rdf_type)
            delete_predicate(subject, predicate, values_to_delete)
          else
            delete_predicate(subject, predicate)
          end
        end
      else
        delete_predicate(subject, predicate)
      end
    end


    def find_values_with_class(subject, predicate, rdf_type)
      matching = []
      query = RDF::Query.new do
        pattern [subject, predicate, :value]
      end
      query.execute(graph).each do |solution|
        if rdf_type
          query2 = RDF::Query.new do
            pattern [solution.value, RDF.type, rdf_type]
          end
          query2.execute(graph).each do |sol2|
            matching << solution.value
          end
        else
          matching << solution.value
        end
      end
      matching 
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

    module ClassMethods
      def config
        @config ||= {}
      end

      def map_predicates(&block)
        builder = Builder.new(self)
        builder.build &block
      end

      def rdf_type(uri_or_string=nil)
        if uri_or_string
          uri = uri_or_string.kind_of?(RDF::URI) ? uri_or_string : RDF::URI.new(uri_or_string) 
          self.config[:type] = {predicate: RDF.type}
          @rdf_type = uri
          ActiveFedora::RdfNode.rdf_registry[uri] = self
        end
        @rdf_type
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

