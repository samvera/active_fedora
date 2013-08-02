module ActiveFedora
  module RdfNode
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    include ActiveFedora::Rdf::NestedAttributes

    autoload :TermProxy

    # Mapping from URI to ruby class
    def self.rdf_registry
      @@rdf_registry ||= {}
    end

    # Comparison Operator
    # Checks that 
    #   * RDF subject id (URI) is same
    #   * Class is the same
    #   * Both objects reference the same RDF graph in memory
    def ==(other_object)
      self.class == other_object.class &&
      self.rdf_subject.id == other_object.rdf_subject.id &&
      self.graph.object_id == other_object.graph.object_id
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

    def reset_child_cache!
      @target = {}
    end

    # @param [RDF::URI] subject the base node to start the search from
    # @param [Symbol] term the term to get the values for
    def get_values(subject, term)
      options = config_for_term_or_uri(term)
      predicate = options.predicate
      @target ||= {}
      @target[term.to_s] ||= TermProxy.new(self, subject, predicate, options)
    end

    def target_class(predicate)
      _, conf = self.class.config_for_predicate(predicate)
      class_name = conf.class_name
      return nil unless class_name
      ActiveFedora.class_from_string(class_name, self.class)
    end

    def mark_for_destruction
      @marked_for_destruction = true
    end

    def marked_for_destruction?
      @marked_for_destruction
    end

    def new_record= val
      @new_record = val
    end

    def new_record?
      @new_record
    end

    # if there are any existing statements with this predicate, replace them
    # @param [RDF::URI] subject  the subject to insert into the graph
    # @param [Symbol, RDF::URI] term the term to insert into the graph
    # @param [Array,#to_s] values  the value/values to insert into the graph
    def set_value(subject, term, values)
      options = config_for_term_or_uri(term)
      predicate = options.predicate
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

      @target ||= {}
      proxy = @target[term.to_s]
      proxy ||= TermProxy.new(self, subject, predicate, options)
      proxy.reset!
      proxy

    end

    # Be careful with destroy. It will still be in the cache untill you call reset()
    def destroy
      # delete any statements about this rdf_subject
      subject = rdf_subject
      query = RDF::Query.new do
        pattern [subject, :predicate, :value]
      end

      query.execute(graph).each do |solution|
        graph.delete [subject, solution.predicate, solution.value]
      end

      # delete any statements that reference this rdf_subject
      query = RDF::Query.new do
        pattern [:subject, :predicate, subject]
      end

      query.execute(graph).each do |solution|
        graph.delete [solution.subject, solution.predicate, subject]
      end
    end

    # @option [Hash] values the values to assign to this rdf node.
    def attributes=(values)
      raise ArgumentError, "values must be a Hash, you provided #{values.class}" unless values.kind_of? Hash
      values.with_indifferent_access.each do |key, value|
        if self.class.config.keys.include?(key)
          set_value(rdf_subject, key, value)
        elsif nested_attributes_options.keys.map{ |k| "#{k}_attributes"}.include?(key)
          send("#{key}=".to_sym, value)
        end
      end
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
      reset_child_cache!
    end

    # append a value 
    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def append(subject, predicate, args)
      options = config_for_term_or_uri(predicate)
      graph.insert([subject, predicate, args])
    end

    def config_for_term_or_uri(term)
      case term
      when RDF::URI
        self.class.config.each { |k, v| return v if v.predicate == term}
      else
        self.class.config[term.to_sym]
      end
    end

    # @param [Symbol, RDF::URI] term predicate  the predicate to insert into the graph
    def find_predicate(term)
      conf = config_for_term_or_uri(term)
      conf ? conf.predicate : nil
    end

    def query subject, predicate, &block
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      
      q = RDF::Query.new do
        pattern [subject, predicate, :value]
      end

      q.execute(graph, &block)
    end

    def method_missing(name, *args)
      if md = /^([^=]+)=$/.match(name.to_s)
          set_value(rdf_subject, md[1], *args)  
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
        vocab = args.delete(:in)
        field = args.delete(:to) {name}.to_sym
        raise "Vocabulary '#{vocab.inspect}' does not define property '#{field.inspect}'" unless vocab.respond_to? field
        @parent.config[name] = Rdf::NodeConfig.new(vocab.send(field), args).tap do |config|
          config.with_index(&block) if block_given?
        end
      end

    end

    module ClassMethods
      def config
        @config ||= {}.with_indifferent_access
      end

      # List of symbols representing the fields for this terminology.
      # ':type' is excluded because it represents RDF.type and is a fixed value
      # @see rdf_type
      def fields
        config.keys.map(&:to_sym) - [:type]
      end

      def map_predicates(&block)
        builder = Builder.new(self)
        builder.build &block
      end

      # Provide the value for the RDF.type of this node
      # @example
      #   class Location 
      #     include ActiveFedora::RdfObject
      #     rdf_type RDF::EbuCore.Location
      #   end
      def rdf_type(uri_or_string=nil)
        if uri_or_string
          uri = uri_or_string.kind_of?(RDF::URI) ? uri_or_string : RDF::URI.new(uri_or_string) 
          self.config[:type] = Rdf::NodeConfig.new(RDF.type)
          @rdf_type = uri
          logger.warn "Duplicate RDF Class. Trying to register #{self} for #{uri} but it is already registered for #{ActiveFedora::RdfNode.rdf_registry[uri]}" if ActiveFedora::RdfNode.rdf_registry.key? uri
          ActiveFedora::RdfNode.rdf_registry[uri] = self
        end
        @rdf_type
      end

      def config_for_predicate(predicate)
        config.each do |term, value|
          return term, value if value.predicate == predicate
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

