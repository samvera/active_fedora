module ActiveFedora
  class RDFDatastream < Datastream
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

    module ModelMethods
      extend ActiveSupport::Concern
      module ClassMethods
        attr_accessor :vocabularies
        def config
          ActiveFedora::Predicates.predicate_config
        end
        def prefix(name)
          name = name.to_s unless name.is_a? String
          pre = self.to_s.sub(/RDFDatastream$/i, '').underscore
          return "#{pre}__#{name}".to_sym
        end

        ##
        # Register a ruby block that evaluates to the subject of the graph
        # By default, the block returns the current object's pid
        # @yield [ds] 'ds' is the datastream instance
        def rdf_subject &block
          if block_given?
             return @subject_block = block
          end

          @subject_block ||= lambda { |ds| "info:fedora/#{ds.pid}" }
        end

        def register_vocabularies(*vocabs)
          @vocabularies ||= {}
          vocabs.each do |v|
            if v.is_a?(RDF::Vocabulary) or (v.respond_to? :property and v.respond_to? :to_uri)
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
        def method_missing(name, *args, &block)
          args = args.first if args.respond_to? :first
          raise "mapping must specify RDF vocabulary as :in argument" unless args.has_key? :in
          vocab = args[:in]
          predicate = args.fetch(:to, name)
          raise "Vocabulary '#{vocab.inspect}' does not define property '#{predicate.inspect}'" unless vocab.respond_to? predicate
          indexing = false
          if block_given?
            # needed for solrizer integration
            indexing = true
            iobj = IndexObject.new
            yield iobj
            data_type = iobj.data_type
            behaviors = iobj.behaviors
          end
          # needed for AF::Predicates integration & drives all other
          # functionality below
          vocab = vocab.to_s
          name = self.prefix(name)
          if config
            if config[:predicate_mapping].has_key? vocab
              config[:predicate_mapping][vocab][name] = predicate
            else
              config[:predicate_mapping][vocab] = { name => predicate } 
            end
            # stuff data_type and behaviors in there for to_solr support
            config[:predicate_mapping][vocab]["#{name}__type".to_sym] = data_type if indexing
            config[:predicate_mapping][vocab]["#{name}__behaviors".to_sym] = behaviors if indexing
          else
            config = {
              :default_namespace => vocab,
              :predicate_mapping => {
                vocab => { name => predicate }
              }
            }
            # stuff data_type and behaviors in there for to_solr support
            config[:predicate_mapping][vocab]["#{name}__type".to_sym] = data_type if indexing
            config[:predicate_mapping][vocab]["#{name}__behaviors".to_sym] = behaviors if indexing
          end
        end
      end
    end
    class TermProxy
      # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
      # @param [ActiveFedora::RelationshipGraph] graph  the graph
      # @param [Array] values  an array of object values
      instance_methods.each { |m| undef_method m unless m.to_s =~ /^(?:nil\?|send|object_id|to_a)$|^__|^respond_to|proxy_/ }
      
      def initialize(graph, predicate, values=[])
        @graph = graph
        @predicate = predicate
        @values = values
      end
      def <<(*values)
        @values.concat(values)
        values.each { |value| @graph.add(@predicate, value, true) }
        @graph.dirty = true
        @values
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
      def method_missing(method, *args)
        unless @values.respond_to?(method)
          message = "undefined method `#{method.to_s}' for \"#{@values}\":#{@values.class.to_s}"
          raise NoMethodError, message
        end

        if block_given?
          @values.send(method, *args)  { |*block_args| yield(*block_args) }
        else
          @values.send(method, *args)
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

    def dirty?
      graph.dirty
    end

    def save
      super
      graph.dirty = false
    end

    def serialize! # :nodoc:
      return unless dirty?
      return unless loaded
      self.content = serialize
    end

    def content=(content)
      super
      @graph = RelationshipGraph.new
      deserialize(content)
    end

    # returns a Hash, e.g.: {field => {:values => [], :type => :something, :behaviors => []}, ...}
    def fields
      ensure_loaded
      field_map = {}
      graph.relationships.each do |predicate, values|
        vocab_sym, name = predicate.qname
        uri, vocab = self.class.vocabularies.select { |ns, v| v.__prefix__ == vocab_sym }.first
        next unless vocab

        config = self.class.config[:predicate_mapping][vocab.to_s]

        name, indexed_as = config.select { |k, v| name.to_s == v.to_s && k.to_s.split("__")[0] == self.class.prefix(name).to_s.split("__")[0]}.first
        next unless name and config.has_key?("#{name}__type".to_sym) and config.has_key?("#{name}__behaviors".to_sym)
        type = config["#{name}__type".to_sym]
        behaviors = config["#{name}__behaviors".to_sym]
        field_map[name.to_sym] = {:values => values.map {|v| v.to_s}, :type => type, :behaviors => behaviors}
      end
      field_map
    end

    def to_solr(solr_doc = Hash.new) # :nodoc:
      ensure_loaded
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
      predicate = self.class.prefix(predicate) unless predicate.kind_of? RDF::URI
      result = ActiveFedora::Predicates.find_predicate(predicate)
      RDF::URI(result.reverse.join)
    end

    # Populate a RDFDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF content
    # @param [String] data the "rdf" node 
    def deserialize(data)
      unless data.nil?
        RDF::Reader.for(serialization_format).new(data) do |reader|
          reader.each_statement do |statement|
            begin
              next unless statement.subject == rdf_subject
            rescue
            end
            literal = statement.object.kind_of?(RDF::Literal)
            object = literal ? statement.object.value : statement.object.to_s
            graph.add(statement.predicate, object, literal)
          end
        end
      end
      graph
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
        values << (object.kind_of?(RDF::Literal) ? object.value : object.to_s)
      end
      TermProxy.new(graph, predicate, values)
    end

    # if there are any existing statements with this predicate, replace them
    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def set_value(predicate, args)
      ensure_loaded
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      graph.delete(predicate)
      args = [args] unless args.respond_to? :each
      args.each do |arg|
        graph.add(predicate, arg, true) unless arg.empty?
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

    ##
    # Get the subject for this rdf/xml datastream
    def rdf_subject
      @subject ||= self.class.rdf_subject.call(self)
    end   

    # Creates a RDF datastream for insertion into a Fedora Object
    # Note: This method is implemented on SemanticNode instead of RelsExtDatastream because SemanticNode contains the relationships array
    def serialize
      out = RDF::Writer.for(serialization_format).buffer do |writer|
        graph.to_graph(rdf_subject).each_statement do |statement|
          writer << statement
        end
      end
      graph.dirty = false
      out
    end
  end
end

