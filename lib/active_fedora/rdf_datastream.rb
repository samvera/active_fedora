module ActiveFedora
  class RDFDatastream < Datastream

    before_save do
      if content.blank?
        logger.warn "Cowardly refusing to save a datastream with empty content: #{self.inspect}"
        false
      end
    end
    include RdfNode

    
    class << self 
      attr_accessor :vocabularies
      ##
      # Register a ruby block that evaluates to the subject of the graph
      # By default, the block returns the current object's pid
      # @yield [ds] 'ds' is the datastream instance
      # This should override the method in rdf_object, which just creates a b-node by default
      def rdf_subject &block
        if block_given?
           return @subject_block = block
        end

        @subject_block ||= lambda { |ds| RDF::URI.new("info:fedora/#{ds.pid}") }
      end

      def register_vocabularies(*vocabs)
        Deprecation.warn(RDFDatastream, "register_vocabularies no longer has any effect and will be removed in active-fedora 6.0", caller)
      end

      def prefix(name)
        name = name.to_s unless name.is_a? String
        pre = self.to_s.sub(/RDFDatastream$/i, '').underscore
        return "#{pre}__#{name}".to_sym
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
        
        name, config = self.class.config_for_predicate(predicate)
        next unless config
        type = config[:type]
        behaviors = config[:behaviors]
        next unless type and behaviors 
        field_map[name] ||= {:values => [], :type => type, :behaviors => behaviors}
        field_map[name][:values] << value.to_s
      end
      field_map
    end

    def to_solr(solr_doc = Hash.new) # :nodoc:
      fields.each do |field_key, field_info|
        values = field_info.fetch(:values, false)
        if values
          field_info[:behaviors].each do |index_type|
            field_symbol = ActiveFedora::SolrService.solr_name(self.class.prefix(field_key), field_info[:type], index_type)
            values = [values] unless values.respond_to? :each
            values.each do |val|    
              ::Solrizer::Extractor.insert_solr_field_value(solr_doc, field_symbol, val)         
            end
          end
        end
      end
      solr_doc
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


    def serialization_format
      raise "you must override the `serialization_format' method in a subclass"
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

