module ActiveFedora
  class RelationshipGraph

    attr_accessor :relationships, :dirty


    def initialize
      self.dirty = false
      self.relationships = {}
    end
    
    def add(predicate, object, literal=false)
      unless relationships.has_key? predicate
        relationships[predicate] = []
      end
      object = RDF::Literal.new(object) if literal
      unless relationships[predicate].include?(object)
        @dirty = true
        relationships[predicate] << object
      end
    end

    def delete(predicate, object)
      return unless relationships.has_key? predicate
      if relationships[predicate].include?(object)
        @dirty = true
        relationships[predicate].delete(object)
      end
      if object.respond_to?(:internal_uri) && relationships[predicate].include?(object.internal_uri)
        @dirty = true
        relationships[predicate].delete(object.internal_uri)
      elsif object.is_a? String 
        relationships[predicate].delete_if{|obj| obj.respond_to?(:internal_uri) && obj.internal_uri == object}
      end

    end

    def [](predicate)
      relationships[predicate]
    end
    
    def to_graph(subject_uri)
      # need to destroy relationships and rewrite it.
      subject =  RDF::URI.new(subject_uri)
      graph = RDF::Graph.new
      relationships.each do |predicate, values|
        values.each do |object|
          graph.insert build_statement(subject,  predicate, object)
        end
      end

      graph
    end

    # Create an RDF statement
    # @param uri a string represending the subject
    # @param predicate a predicate symbol
    # @param target an object to store
    def build_statement(uri, predicate, target)
      raise "Not allowed anymore" if uri == :self
      target = target.internal_uri if target.respond_to? :internal_uri
      subject =  RDF::URI.new(uri)  #TODO cache
      if target.is_a? RDF::Literal or target.is_a? RDF::Resource
        object = target
      else
        begin
          target_uri = (target.is_a? URI) ? target : URI.parse(target)
          if target_uri.scheme.nil?
            raise ArgumentError, "Invalid target \"#{target}\". Must have namespace."
          end
          if target_uri.to_s =~ /\A[\w\-]+:[\w\-]+\Z/
            raise ArgumentError, "Invalid target \"#{target}\". Target should be a complete URI, and not a pid."
          end
        rescue URI::InvalidURIError
          raise ArgumentError, "Invalid target \"#{target}\". Target must be specified as a literal, or be a valid URI."
        end
        object = RDF::URI.new(target)
      end
      RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(predicate), object)
    
    end

    # def find_graph_predicate(predicate)
    #     #TODO, these could be cached
    #     case predicate
    #     when :has_model, "hasModel", :hasModel
    #       xmlns="info:fedora/fedora-system:def/model#"
    #       begin
    #         rel_predicate = ActiveFedora::Predicates.predicate_lookup(predicate,xmlns)
    #       rescue UnregisteredPredicateError
    #         xmlns = nil
    #         rel_predicate = nil
    #       end
    #     else
    #       xmlns="info:fedora/fedora-system:def/relations-external#"
    #       begin
    #         rel_predicate = ActiveFedora::Predicates.predicate_lookup(predicate,xmlns)
    #       rescue UnregisteredPredicateError
    #         xmlns = nil
    #         rel_predicate = nil
    #       end
    #     end
    #     
    #     unless xmlns && rel_predicate
    #       rel_predicate, xmlns = ActiveFedora::Predicates.find_predicate(predicate)
    #     end
    #     self.class.vocabularies[xmlns][rel_predicate] 
    # end
    # def self.vocabularies
    #   return @vocabularies if @vocabularies
    #   @vocabularies = {}
    #   predicate_mappings.keys.each { |ns| @vocabularies[ns] = RDF::Vocabulary.new(ns)}
    #   @vocabularies
    # end

    # # If predicate is a symbol, looks up the predicate in the predicate_mappings
    # # If predicate is not a Symbol, returns the predicate untouched
    # # @raise UnregisteredPredicateError if the predicate is a symbol but is not found in the predicate_mappings
    # def self.predicate_lookup(predicate,namespace="info:fedora/fedora-system:def/relations-external#")
    #   if predicate.class == Symbol 
    #     if predicate_mappings[namespace].has_key?(predicate)
    #       return predicate_mappings[namespace][predicate]
    #     else
    #       raise ActiveFedora::UnregisteredPredicateError
    #     end
    #   end
    #   return predicate
    # end

    # def self.predicate_config
    #   @@predicate_config ||= YAML::load(File.open(ActiveFedora.predicate_config)) if File.exist?(ActiveFedora.predicate_config)
    # end

    # def self.predicate_mappings
    #   predicate_config[:predicate_mapping]
    # end

    # def self.default_predicate_namespace
    #   predicate_config[:default_namespace]
    # end

    # def self.find_predicate(predicate)
    #   predicate_mappings.each do |namespace,predicates|
    #     if predicates.fetch(predicate,nil)
    #       return predicates[predicate], namespace
    #     end
    #   end
    #   raise ActiveFedora::UnregisteredPredicateError, "Unregistered predicate: #{predicate.inspect}"
    # end

  end
end
