require 'rdf'

module ActiveFedora
  class RDFDatastream < Datastream
    module ModelMethods
      extend ActiveSupport::Concern
      module ClassMethods
        def config
          ActiveFedora::Predicates.predicate_config
        end
        def map_predicates(&block)
          yield self
        end
        def method_missing(name, *args)
          args = args.first if args.respond_to? :first
          raise "mapping must specify RDF vocabulary as :in argument" unless args.has_key? :in
          vocab = args[:in]
          predicate = args.fetch(:to, name)
          raise "Vocabulary '#{vocab.inspect}' does not define property '#{predicate.inspect}'" unless vocab.respond_to? predicate
          vocab = vocab.to_s
          if config 
            if config[:predicate_mapping].has_key? vocab
              config[:predicate_mapping][vocab][name] = predicate
            else
              config[:predicate_mapping][vocab] = { name => predicate }
           end
          else
            config = {
              :default_namespace => vocab,
              :predicate_mapping => {
                vocab => { name => predicate }
              }
            }
          end
        end
      end
    end

    include ModelMethods
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

    def find_predicate(predicate)
      result = ActiveFedora::Predicates.find_predicate(predicate.to_sym)
      return RDF::URI(result.reverse.to_s)
    end

    def graph
      @graph ||= RelationshipGraph.new
    end

    def get_values(predicate)
      ensure_loaded
      results = graph[find_predicate(predicate)]
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

    # if there are any existing statements with this predicate, replace them
    def set_value(predicate, args)
      ensure_loaded
      graph.delete(predicate)
      args.each do |arg|
        graph.add(predicate, arg, true)
      end
      graph.dirty = true
      return {predicate => args}
    end

    # append a value 
    def append(predicate, args)
      ensure_loaded
      graph.add(predicate, args, true)
      graph.dirty = true
      return {predicate => args}
    end

    def serialization_format
      raise "you must override the `serialization_format' method in a subclass"
    end

    def serialization_format
      raise "you must override the `serialization_format' method in a subclass"
    end

    def method_missing(name, *args)
      if (md = /^([^=]+)=$/.match(name.to_s)) && pred = find_predicate(md[1])
        set_value(pred, *args)  
       elsif pred = find_predicate(name)
        get_values(name)
      else 
        super
      end
    end
    
    # Populate a RDFDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [String] the "rdf" node 
    def deserialize(data) 
      unless data.nil?
        RDF::Reader.for(serialization_format).new(data) do |reader|
          reader.each_statement do |statement|
            next unless statement.subject == "info:fedora/#{pid}"
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

