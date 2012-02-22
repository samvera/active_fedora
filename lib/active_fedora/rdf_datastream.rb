Brequire 'rdf'

module ActiveFedora
  class RDFDatastream < Datastream
    module ModelMethods
      extend ActiveSupport::Concern
      module ClassMethods
        attr_accessor :vocabularies, :predicate_map
        def register_vocabularies(*vocabs)
          @vocabularies ||= []
          vocabs.each do |v|
            if v.respond_to? :property and v.respond_to? :to_uri
              @vocabularies << v 
            else
              raise "not an RDF vocabulary: #{v}"
            end
          end
        end
        def map_predicates(&block)
          @predicate_map ||= {}
          yield self
        end
        def method_missing(name, args)
          raise "mapping must include :to and :in args" unless args.has_key? :to and args.has_key? :in
          vocab, property = args[:in], args[:to]
          raise "vocabulary not registered: #{vocab}" unless @vocabularies.include? vocab
          raise "property #{property} not found in #{vocab}" unless vocab.respond_to? property
          @predicate_map[name] = vocab.send(property)
        end
      end
    end
    
    attr_accessor :loaded

    def ensure_loaded
      return if loaded 
      self.loaded = true
      unless new?
        deserialize content
      end
    end
    
    def serialize! # :nodoc:
      if graph.dirty
        return unless loaded 
        self.content = serialize
      end
    end

    def graph
      @graph ||= RelationshipGraph.new
    end

    # Update field values within the current datastream using {#update_values}
    # Ignores any fields from params that this datastream's predicate mappings don't recognize    
    #
    # @param [Hash] params The params specifying which fields to update and their new values.  The syntax of the params Hash is the same as that expected by 
    #         term_pointers must be a valid OM Term pointers (ie. [:name]).  Strings will be ignored.
    # @param [Hash] opts This is not currently used by the datastream-level update_indexed_attributes method
    def update_indexed_attributes(params={}, opts={})    
      if ActiveFedora::Predicates.predicate_mappings.empty?
        raise "No predicates are set for this RDFDatastream class.  Cannot perform update_indexed_attributes"
      end
      ensure_loaded
      # remove any fields from params that this datastream doesn't recognize    
      # make sure to make a copy of params so not to modify hash that might be passed to other methods
      current_params = params.clone
      current_params.delete_if do |pred, new_values| 
        !ActiveFedora::Predicates.predicate_mappings.fetch(pred.first.to_sym, false)
      end
      mapped_params = Hash[*current_params.collect do |k,v| 
                             [ActiveFedora::Predicates.predicate_mappings[k.first.to_sym], v]
                           end.flatten]
      result = {}
      unless mapped_params.empty?
        result = update_values(mapped_params)
      end      
      result
    end

    def get_values(predicate)
      ensure_loaded
      pred = ActiveFedora::Predicates.find_predicate(predicate).reverse.to_s
      #puts "pred: #{pred.inspect}" if predicate == :created
      #puts "graph: #{graph.inspect}" if predicate == :created
      results = graph[RDF::URI(pred)]
      #puts "results: #{results.inspect}" if predicate == :created
      return if results.nil?
      res = []
      results.each do |object|
        res << (object.kind_of?(RDF::Literal) ? object.value : object.to_str)
      end
      res
    end

    def to_solr
      # TODO
    end

    def update_values(params)
      params.each_pair do |pred, value|
        set_value(pred, value)
      end
      graph.dirty = true
    end
  
    # if there are any existing statements with this predicate, replace them
    def set_value(predicate, args)
      ensure_loaded
      predicate = RDF::URI(predicate.reverse.to_s) if predicate.is_a? Array
      #puts "pred: #{predicate.inspect}"
      #puts "graph: #{graph.inspect}"
      #puts "args: #{args.inspect}"
      graph.delete(predicate)
      graph.add(predicate, args, true)
      #puts "graph: #{graph.inspect}"
    end

    # append a value 
    def append(predicate, args)
      ensure_loaded
      graph.add(predicate, args, true)
    end

    def method_missing(name, *args)
      if (md = /^([^=]+)=$/.match(name.to_s)) && pred = ActiveFedora::Predicates.find_predicate(md[1].to_sym)
        #puts "tried to find #{md[1].inspect}"
        #puts "passing #{pred.inspect}"
        set_value(pred, *args)  
      elsif pred = ActiveFedora::Predicates.find_predicate(name)
        get_values(name)
      else 
        super
      end
    end

    def serialization_format
      raise "you must override the `serialization_format' method in a subclass"
    end
    
    # Populate a RDFDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [String] the "rdf" node 
    def deserialize(data) 
      unless data.nil?
        RDF::Reader.for(serialization_format).new(data) do |reader|
          reader.each_statement do |statement|
            next unless statement.subject == "info:fedora/#{self.pid}"
            literal = statement.object.kind_of?(RDF::Literal)
            object = literal ? statement.object.value : statement.object.to_str
            graph.add(statement.predicate, object, literal)
          end
        end
      end
      graph
    end
    #alias_method :content=, :deserialize

    # Creates a RDF datastream for insertion into a Fedora Object
    # @param [String] pid
    # @param [Hash] relationships (optional) @default self.relationships
    # Note: This method is implemented on SemanticNode instead of RelsExtDatastream because SemanticNode contains the relationships array
    def serialize()
      out = RDF::Writer.for(serialization_format).buffer do |writer|
        graph.to_graph("info:fedora/#{pid}").each_statement do |statement|
          writer << statement
        end
      end
      out
    end
  end
end

