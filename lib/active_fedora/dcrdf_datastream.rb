require 'rdf'
require 'rdf/ntriples'

module ActiveFedora
  class DCRDFDatastream < Datastream
    attr_accessor :loaded

    def mimeType
      'text/plain'
    end

    def controlGroup
      'M'
    end

    def ensure_loaded
      return if loaded 
      self.loaded = true
      unless new?
        from_ntriple content
      end
    end
    
    def serialize! # :nodoc:
      if graph.dirty
        return unless loaded 
        self.content = self.to_ntriple
      end
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

    def resolve_predicate(name)
      RDF::DC.send(name) if RDF::DC.respond_to? name
    end

    def graph
      @graph ||= RelationshipGraph.new
    end


    # Populate a RDFDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [String] the "rdf" node 
    def from_ntriple(data) 
      unless data.nil?
        RDF::Reader.for(:ntriples).new(data) do |reader|
          reader.each_statement do |statement|
            literal = statement.object.kind_of?(RDF::Literal)
            object = literal ? statement.object.value : statement.object.to_str
            graph.add(statement.predicate, object, literal)
          end
        end
      end
      graph
    end

    # Creates a RELS-EXT datastream for insertion into a Fedora Object
    # @param [String] pid
    # @param [Hash] relationships (optional) @default self.relationships
    # Note: This method is implemented on SemanticNode instead of RelsExtDatastream because SemanticNode contains the relationships array
    def to_ntriple()
      out = RDF::Writer.for(:ntriples).buffer do |writer|
        graph.to_graph("info:fedora/#{pid}").each_statement do |statement|
          writer << statement
        end
      end
      out
    end
    
    

  end
end
