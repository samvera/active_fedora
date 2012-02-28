Brequire 'rdf'

module ActiveFedora
  class RDFDatastream < Datastream
    module ModelMethods
      extend ActiveSupport::Concern
      module ClassMethods
        include ActiveFedora::Predicates
        def map_predicates(&block)
          yield self
        end
        def method_missing(name, *args)
          args = args.first if args.respond_to? :first
          raise "mapping must specify RDF vocabulary as :in argument" unless args.has_key? :in
          vocab = args[:in].to_s
          predicate = args.fetch(:to, name)
          if ActiveFedora::Predicates.predicate_config 
            unless ActiveFedora::Predicates.predicate_config[:predicate_mapping].has_key? vocab
              ActiveFedora::Predicates.predicate_config[:predicate_mapping][vocab] = { name => predicate }
            else
              ActiveFedora::Predicates.predicate_config[:predicate_mapping][vocab][name] = predicate
            end
          else
            ActiveFedora::Predicates.predicate_config = {
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

    def graph
      @graph ||= RelationshipGraph.new
    end

    def get_values(predicate)
      ensure_loaded
      pred = ActiveFedora::Predicates.find_predicate(predicate).reverse.to_s
      results = graph[RDF::URI(pred)]
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
      predicate = RDF::URI(predicate.reverse.to_s) if predicate.is_a? Array
      graph.delete(predicate)
      graph.add(predicate, args, true)
      graph.dirty = true
      return {predicate => args}
    end

    # append a value 
    def append(predicate, args)
      ensure_loaded
      graph.add(predicate, args, true)
    end

    def serialization_format
      raise "you must override the `serialization_format' method in a subclass"
    end

    def method_missing(name, *args)
      if (md = /^([^=]+)=$/.match(name.to_s)) && pred = ActiveFedora::Predicates.find_predicate(md[1].to_sym)
        set_value(pred, *args)  
      elsif pred = ActiveFedora::Predicates.find_predicate(name)
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

