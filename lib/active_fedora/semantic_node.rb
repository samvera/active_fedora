module ActiveFedora
  module SemanticNode 
    extend ActiveSupport::Concern
    extend Deprecation

    attr_accessor :relationships_loaded
    attr_accessor :load_from_solr, :subject

    def assert_kind_of(n, o,t)
      raise "Assertion failure: #{n}: #{o} is not of type #{t}" unless o.kind_of?(t)
    end

    def clear_relationships
      @relationships_loaded = false
      @object_relations = nil
    end

    def object_relations
      load_relationships if !relationships_loaded
      @object_relations ||= RelationshipGraph.new
    end

    def relationships_are_dirty?
      object_relations.dirty
    end
    alias relationships_are_dirty relationships_are_dirty?

    def relationships_are_not_dirty!
      object_relations.dirty = false
    end

    def relationships=(xml)
      RDF::RDFXML::Reader.new(xml) do |reader|
        reader.each_statement do |statement|
          literal = statement.object.kind_of?(RDF::Literal)
          object = literal ? statement.object.value : statement.object.to_str
          object_relations.add(statement.predicate, object, literal)
        end
      end
      # Adding the relationships to the graph causes the graph to be marked as dirty,
      # so now we assert that the graph is in sync
      relationships_are_not_dirty!
    end

    # Add a relationship to the Object.
    # @param [Symbol, String] predicate
    # @param [URI, ActiveFedora::Base] target Either a string URI or an object that is a kind of ActiveFedora::Base 
    # TODO is target ever a AF::Base anymore?
    def add_relationship(predicate, target, literal=false)
      #raise ArgumentError, "predicate must be a symbol. You provided `#{predicate.inspect}'" unless predicate.class.in?([Symbol, String])
      object_relations.add(predicate, target, literal)
      rels_ext.content_will_change! if object_relations.dirty
    end

    # Clears all relationships with the specified predicate
    # @param predicate
    def clear_relationship(predicate)
      relationships(predicate).each do |target|
        object_relations.delete(predicate, target) 
      end
      rels_ext.content_will_change! if object_relations.dirty
    end

    # Checks that this object is matches the model class passed in.
    # It requires two steps to pass to return true
    #   1. It has a hasModel relationship of the same model
    #   2. kind_of? returns true for the model passed in
    # This method can most often be used to detect if an object from Fedora that was created
    # with a different model was then used to populate this object.
    # @param [Class] model_class the model class name to check if an object conforms_to that model
    # @return [Boolean] true if this object conforms to the given model name
    def conforms_to?(model_class)
      if self.kind_of?(model_class)
        #check has model and class match
        mod = relationships.first(:predicate=>Predicates.find_graph_predicate(:has_model))
        if mod
          expected = self.class.to_class_uri
          if mod.object.to_s == expected
            return true
          else
            raise "has_model relationship check failed for model #{model_class} raising exception, expected: '#{expected}' actual: '#{mod.object.to_s}'"
          end
        else
          raise "has_model relationship does not exist for model #{model_class} check raising exception"
        end
      else
        raise "kind_of? check failed for model #{model_class}, actual #{self.class} raising exception"
      end
      return false
    end

    #
    # Remove a Rels-Ext relationship from the Object.
    # @param predicate
    # @param obj Either a string URI or an object that responds to .pid 
    def remove_relationship(predicate, obj, literal=false)
      object_relations.delete(predicate, obj)
      object_relations.dirty = true
      rels_ext.content_will_change!
    end

    # If no arguments are supplied, return the whole RDF::Graph.
    # if a predicate is supplied as a parameter, then it returns the result of quering the graph with that predicate
    def relationships(*args)
      load_relationships unless relationships_loaded

      if args.empty?
        raise "Must have internal_uri" unless internal_uri
        return object_relations.to_graph(internal_uri)
      end
      rels = object_relations[args.first] || []
      rels.map {|o| o.respond_to?(:internal_uri) ? o.internal_uri : o }.compact   #TODO, could just return the object
    end

    def load_relationships
      @relationships_loaded = true
      content = rels_ext.content
      return unless content.present?
      RelsExtDatastream.from_xml content, rels_ext
    end

    def ids_for_outbound(predicate)
      (object_relations[predicate] || []).map do |o|
        o = o.to_s if o.kind_of? RDF::Literal
        o.kind_of?(String) ? self.class.pid_from_uri(o) : o.pid
      end
    end

    # @return [String] the internal fedora URI
    def internal_uri
      self.class.internal_uri(pid)
    end

    module ClassMethods
      # @param [String,Array] uris a single uri (as a string) or a list of uris to convert to pids
      # @return [String] the pid component of the URI
      def pids_from_uris(uris) 
        Deprecation.warn(SemanticNode, "pids_from_uris has been deprecated and will be removed in active-fedora 8.0.0", caller)
        if uris.kind_of? String
          pid_from_uri(uris)
        else
          Array(uris).map {|uri| pid_from_uri(uri)}
        end
      end

      # Returns a suitable uri object for :has_model
      # Should reverse Model#from_class_uri
      def to_class_uri(attrs = {})
        if self.respond_to? :pid_suffix
          pid_suffix = self.pid_suffix
        else
          pid_suffix = attrs.fetch(:pid_suffix, ContentModel::CMODEL_PID_SUFFIX)
        end
        if self.respond_to? :pid_namespace
          namespace = self.pid_namespace
        else
          namespace = attrs.fetch(:namespace, ContentModel::CMODEL_NAMESPACE)
        end
        "info:fedora/#{namespace}:#{ContentModel.sanitized_class_name(self)}#{pid_suffix}" 
      end

      # @param [String] pid the fedora object identifier
      # @return [String] a URI represented as a string
      def internal_uri(pid)
        "info:fedora/#{pid}"
      end

      # @param [String] uri a uri (as a string)
      # @return [String] the pid component of the URI
      def pid_from_uri(uri)
        uri.gsub("info:fedora/", "")
      end

    end
  end
end
