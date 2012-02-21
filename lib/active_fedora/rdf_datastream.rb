require 'rdf'

module ActiveFedora
  class RDFDatastream < Datastream
    module ModelMethods
      attr_accessor :vocabularies, :predicate_map
      def self.included(base)
        base.extend(ClassMethods)
      end
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
          @predicate_map[name.to_sym] = vocab.send(property)
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

    def get_values(predicate)
      ensure_loaded
      predicate = resolve_predicate(predicate) unless predicate.kind_of? RDF::URI
      results = graph[predicate]
      res = []
      results.each do |object|
        res << (object.kind_of?(RDF::Literal) ? object.value : object.to_str)
      end
      res
    end
  
    # if there are any existing statements with this predicate, replace them
    def set_value(predicate, args)
      ensure_loaded
      predicate = resolve_predicate(predicate) unless predicate.kind_of? RDF::URI
      graph.delete(predicate)
      graph.add(predicate, args, true)
    end

    # append a value 
    def append(predicate, args)
      ensure_loaded
      graph.add(predicate, args, true)
    end

    def method_missing(name, *args)
      if pred = resolve_predicate(name) 
        get_values(pred)
      elsif (md = /^([^=]+)=$/.match(name.to_s)) && pred = resolve_predicate(md[1])
        set_value(pred, *args)  
      else 
        super
      end
    end

    def serialization_format
      raise "you must override the `serialization_format' method in a subclass"
    end
    
    # given a symbol or string, map it to a RDF::URI
    # if the provided parameter is not allowed in the vocabulary, return nil
    def resolve_predicate(predicate)
      raise "you must override the `resolve_predicate' method in a subclass"
    end

    # Populate a RDFDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [String] the "rdf" node 
    def deserialize(data) 
      unless data.nil?
        RDF::Reader.for(serialization_format).new(data) do |reader|
          reader.each_statement do |statement|
            literal = statement.object.kind_of?(RDF::Literal)
            object = literal ? statement.object.value : statement.object.to_str
            graph.add(statement.predicate, object, literal)
          end
        end
      end
      graph
    end

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

