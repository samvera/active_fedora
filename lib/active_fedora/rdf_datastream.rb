require 'rdf'

module ActiveFedora
  class RDFDatastream < Datastream
    module ModelMethods
      extend ActiveSupport::Concern
      module ClassMethods
        attr_accessor :vocabularies
        def config
          ActiveFedora::Predicates.predicate_config
        end
        def register_vocabularies(*vocabs)
          @vocabularies = {}
          vocabs.each do |v|
            if v.respond_to? :property and v.respond_to? :to_uri
              @vocabularies[v.to_uri] = v 
            else
              raise "not an RDF vocabulary: #{v}"
            end
          end
          ActiveFedora::Predicates.vocabularies(@vocabularies)
          @vocabularies
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
          # needed for solrizer integration
          indexing = args.fetch(:index_as, false)
          # set data_type default to :string like other impls
          data_type = indexing.fetch(:type, :string) if indexing
          # set behaviors default to :searchable like other impls
          behaviors = indexing.fetch(:behaviors, [:searchable]) if indexing
          # needed for AF::Predicates integration & drives all other
          # functionality below
          if config
            if config[:predicate_mapping].has_key? vocab
              config[:predicate_mapping][vocab][name] = predicate
            else
              config[:predicate_mapping][vocab] = { name => predicate } 
            end
            # stuff data_type and behaviors in there for to_solr support
            config[:predicate_mapping][vocab]["#{name}type".to_sym] = data_type if indexing
            config[:predicate_mapping][vocab]["#{name}behaviors".to_sym] = behaviors if indexing
          else
            config = {
              :default_namespace => vocab,
              :predicate_mapping => {
                vocab => { name => predicate }
              }
            }
            # stuff data_type and behaviors in there for to_solr support
            config[:predicate_mapping][vocab]["#{name}type".to_sym] = data_type if indexing
            config[:predicate_mapping][vocab]["#{name}behaviors".to_sym] = behaviors if indexing
          end
        end
      end
    end

    class TermProxy
      # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
      # @param [ActiveFedora::RelationshipGraph] graph  the graph
      # @param [Array] values  an array of object values
      include Enumerable
      def initialize(graph, predicate, values=[])
        @graph = graph
        @predicate = predicate
        @values = values
      end
      def each(&block)
        @values.each { |value| block.call(value) }
      end
      def <<(*values)
        @values.concat(values)
        values.each { |value| @graph.add(@predicate, value, true) }
        @graph.dirty = true
        @values
      end
      def ==(other)
        other == @values
      end
      def delete(*values)
        values.each do |value| 
          unless @values.delete(value).nil?
            @graph.delete(@predicate, value)
            @graph.dirty = true
          end
        end
        @values
      end
      def empty?
        @values.empty?
      end
      def to_s
        @values.to_s
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

    # returns a Hash, e.g.: {field => {:values => [], :type => :something, :behaviors => []}, ...}
    def fields
      field_map = {}
      graph.relationships.each do |predicate, values|
        vocab_sym, name = predicate.qname
        vocabs_list = self.class.vocabularies.select { |ns, v| v.__prefix__ == vocab_sym }
        vocab = vocabs_list.first.first.to_s
        vocab_hash = self.class.config[:predicate_mapping][vocab]
        mapped_names = vocab_hash.select {|k, v| v.to_s == name.to_s}
        name = mapped_names.first.first.to_s
        next unless vocab_hash.has_key?("#{name}type".to_sym) and vocab_hash.has_key?("#{name}behaviors".to_sym)
        type = vocab_hash["#{name}type".to_sym]
        behaviors = vocab_hash["#{name}behaviors".to_sym]
        field_map[name.to_sym] = {:values => values.map {|v| v.to_s}, :type => type, :behaviors => behaviors}
      end
      field_map
    end

    def to_solr(solr_doc = Hash.new) # :nodoc:
      fields.each do |field_key, field_info|
        values = field_info.fetch(:values, false)
        if values
          field_info[:behaviors].each do |index_type|
            field_symbol = ActiveFedora::SolrService.solr_name(field_key, field_info[:type], index_type)
            values = [values] unless values.respond_to? :each
            values.each do |val|    
              ::Solrizer::Extractor.insert_solr_field_value(solr_doc, field_symbol, val)         
            end
          end
        end
      end
      solr_doc
    end

    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def find_predicate(predicate)
      predicate = predicate.to_sym unless predicate.kind_of? RDF::URI
      result = ActiveFedora::Predicates.find_predicate(predicate)
      RDF::URI(result.reverse.to_s)
    end

    def graph
      @graph ||= RelationshipGraph.new
    end

    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def get_values(predicate)
      ensure_loaded
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      results = graph[predicate]
      return if results.nil?
      values = []
      results.each do |object|
        values << (object.kind_of?(RDF::Literal) ? object.value : object.to_str)
      end
      TermProxy.new(graph, predicate, values)
    end

    # if there are any existing statements with this predicate, replace them
    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def set_value(predicate, args)
      ensure_loaded
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      graph.delete(predicate)
      args.each do |arg|
        graph.add(predicate, arg, true)
      end
      graph.dirty = true
      return TermProxy.new(graph, predicate, args)
    end

    # append a value 
    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def append(predicate, args)
      ensure_loaded
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      graph.add(predicate, args, true)
      graph.dirty = true
      return TermProxy.new(graph, predicate, args)
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
    # @param [String] data the "rdf" node 
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
    # Note: This method is implemented on SemanticNode instead of RelsExtDatastream because SemanticNode contains the relationships array
    def serialize
      out = RDF::Writer.for(serialization_format).buffer do |writer|
        graph.to_graph("info:fedora/#{pid}").each_statement do |statement|
          writer << statement
        end
      end
      out
    end
  end
end

