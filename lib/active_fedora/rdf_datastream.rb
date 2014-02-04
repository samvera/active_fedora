module ActiveFedora
  class RDFDatastream < Datastream

    before_save do
      if content.blank?
        logger.warn "Cowardly refusing to save a datastream with empty content: #{self.inspect}"
        false
      end
    end
    include RdfNode
    include Rdf::Indexing
    
    class << self 
      ##
      # Register a ruby block that evaluates to the subject of the graph
      # By default, the block returns the current object's pid
      # @yield [ds] 'ds' is the datastream instance
      # This should override the method in RdfObject, which just creates a b-node by default
      def rdf_subject &block
        if block_given?
           return @subject_block = block
        end

        @subject_block ||= lambda { |ds| RDF::URI.new("info:fedora/#{ds.pid}") }
      end
    end

    def freeze
      @graph.freeze
    end

    def metadata?
      true
    end

    # Overriding so that one can call ds.content on an unsaved datastream and they will see the serialized format
    def content
      serialize
    end

    def content=(content)
      reset_child_cache!
      @graph = deserialize(content)
    end

    def content_changed?
      # we haven't touched the graph, so it isn't changed (avoid a force load)
      return false unless instance_variable_defined? :@graph
      @content = serialize
      super
    end
    # Populate a RDFDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF content
    # @param [String] data the "rdf" node 
    def deserialize(data = nil)
      repository = RDF::Repository.new
      return repository if new? and data.nil?

      data ||= datastream_content
      data.force_encoding('utf-8')
      RDF::Reader.for(serialization_format).new(data) do |reader|
        reader.each_statement do |statement|
          repository << statement
        end
      end

      repository
    end

    def graph
      @graph ||= begin
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

    
    private 

    def update_subjects_to_use_a_real_pid!
      return unless new?

      bad_subject = rdf_subject
      reset_rdf_subject!
      reset_child_cache!
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

