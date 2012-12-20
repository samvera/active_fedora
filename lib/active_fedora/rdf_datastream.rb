module ActiveFedora
  class RDFDatastream < Datastream

    before_save do
      if content.blank?
        logger.warn "Cowardly refusing to save a datastream with empty content: #{self.inspect}"
        false
      end
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

    class << self 
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

        @subject_block ||= lambda { |ds| RDF::URI.new("info:fedora/#{ds.pid}") }
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


    class TermProxy

      attr_reader :graph, :subject, :predicate
      delegate :class, :to_s, :==, :kind_of?, :each, :map, :empty?, :as_json, :to => :values

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
    
    attr_accessor :loaded
    def metadata?
      true
    end
    def ensure_loaded
    end

    def content
      serialize
    end

    def content=(content)
      self.loaded = true
      @graph = deserialize(content)
    end

    def content_changed?
      return false if new? and !loaded
      super
    end

    def changed?
      super || content_changed?
    end

    # returns a Hash, e.g.: {field => {:values => [], :type => :something, :behaviors => []}, ...}
    def fields
      field_map = {}

      rdf_subject = self.rdf_subject
      query = RDF::Query.new do
        pattern [rdf_subject, :predicate, :value]
      end

      query.execute(graph).each do |solution|
        predicate = solution.predicate
        value = solution.value
        
        vocab_sym, name = predicate.qname
        uri, vocab = self.class.vocabularies.select { |ns, v| v.__prefix__ == vocab_sym }.first
        next unless vocab

        config = self.class.config[:predicate_mapping][vocab.to_s]

        name, indexed_as = config.select { |k, v| name.to_s == v.to_s && k.to_s.split("__")[0] == self.class.prefix(name).to_s.split("__")[0]}.first
        next unless name and config.has_key?("#{name}__type".to_sym) and config.has_key?("#{name}__behaviors".to_sym)
        type = config["#{name}__type".to_sym]
        behaviors = config["#{name}__behaviors".to_sym]
        field_map[name.to_sym] ||= {:values => [], :type => type, :behaviors => behaviors}
        field_map[name.to_sym][:values] << value.to_s
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
      predicate = self.class.prefix(predicate) unless predicate.kind_of? RDF::URI
      result = ActiveFedora::Predicates.find_predicate(predicate)
      RDF::URI(result.reverse.join)
    end

    # Populate a RDFDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF content
    # @param [String] data the "rdf" node 
    def deserialize(data = nil)
      repository = RDF::Repository.new
      return repository if new? and data.nil?

      data ||= datastream_content

      RDF::Reader.for(serialization_format).new(data) do |reader|
        reader.each_statement do |statement|
          repository << statement
        end
      end

      repository
    end

    def graph
      @graph ||= begin
        self.loaded = true
        deserialize
      end      
    end

    def query subject, predicate, &block
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI
      
      q = RDF::Query.new do
        pattern [subject, predicate, :value]
      end

      q.execute(graph, &block)
    end

    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph
    def get_values(subject, predicate)

      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI

      return TermProxy.new(self, subject, predicate)
    end

    # if there are any existing statements with this predicate, replace them
    # @param [Symbol, RDF::URI] predicate  the predicate to insert into the graph

    def set_value(subject, predicate, values)
      
      predicate = find_predicate(predicate) unless predicate.kind_of? RDF::URI

      delete_predicate(subject, predicate)

      Array(values).each do |arg|
        arg = arg.to_s if arg.kind_of? RDF::Literal
        next if arg.empty?

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


      return TermProxy.new(self, subject, predicate)
    end

    def serialization_format
      raise "you must override the `serialization_format' method in a subclass"
    end

    def method_missing(name, *args)
      if (md = /^([^=]+)=$/.match(name.to_s)) && pred = find_predicate(md[1])
        set_value(rdf_subject, pred, *args)  
       elsif pred = find_predicate(name)
        get_values(rdf_subject, name)
      else 
        super
      end
    rescue ActiveFedora::UnregisteredPredicateError
      super
    end

    ##
    # Get the subject for this rdf/xml datastream
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

    # Creates a RDF datastream for insertion into a Fedora Object
    # Note: This method is implemented on SemanticNode instead of RelsExtDatastream because SemanticNode contains the relationships array
    def serialize
      update_subjects_to_use_a_real_pid!
      RDF::Writer.for(serialization_format).dump(graph)
    end

    def update_subjects_to_use_a_real_pid!
      return unless new?

      bad_subject = rdf_subject
      reset_rdf_subject!
      new_subject = rdf_subject

      new_repository = RDF::Repository.new

      graph.each_statement do |statement|
          subject = statement.subject

          subject &&= new_subject if subject == bad_subject
          new_repository << [subject, statement.predicate, statement.object]
      end

      @graph = new_repository
    end
  end
end

