module ActiveFedora
  module Predicates
    def self.find_graph_predicate(predicate)
      #TODO, these could be cached
      case predicate
      when :has_model, "hasModel", :hasModel
        xmlns="info:fedora/fedora-system:def/model#"
        begin
          rel_predicate = predicate_lookup(predicate,xmlns)
        rescue UnregisteredPredicateError
          xmlns = nil
          rel_predicate = nil
        end
      else
        xmlns="info:fedora/fedora-system:def/relations-external#"
        begin
          rel_predicate = predicate_lookup(predicate,xmlns)
        rescue UnregisteredPredicateError
          xmlns = nil
          rel_predicate = nil
        end
      end
        
      unless xmlns && rel_predicate
        rel_predicate, xmlns = find_predicate(predicate)
      end

      vocabularies[xmlns][rel_predicate] 
    end

    def self.vocabularies(vocabs = {})
      @vocabularies ||= vocabs
      predicate_mappings.keys.each do |ns| 
        @vocabularies[ns] = RDF::Vocabulary.new(ns) unless @vocabularies.has_key? ns
      end
      @vocabularies
    end

    # If predicate is a symbol, looks up the predicate in the predicate_mappings
    # If predicate is not a Symbol, returns the predicate untouched
    # @raise UnregisteredPredicateError if the predicate is a symbol but is not found in the predicate_mappings
    def self.predicate_lookup(predicate,namespace="info:fedora/fedora-system:def/relations-external#")
      if predicate.class == Symbol 
        if predicate_mappings[namespace].has_key?(predicate)
          return predicate_mappings[namespace][predicate]
        else
          raise ActiveFedora::UnregisteredPredicateError
        end
      end
      return predicate
    end

    def self.predicate_config= value
      unless value.nil? or (value.is_a?(Hash) and [:predicate_mapping,:default_namespace].all? { |key| value.has_key? key })
        raise TypeError, "predicate_config must specify :predicate_mapping and :default_namespace" 
      end
      @@predicate_config = value 
    end
    
    def self.predicate_config
      @@predicate_config ||= ActiveFedora.predicate_config
    end

    def self.predicate_namespaces
      predicate_config[:predicate_namespaces] ||= {}
    end
    
    def self.predicate_mappings
      predicate_config[:predicate_mapping]
    end

    def self.default_predicate_namespace
      predicate_config[:default_namespace]
    end

    def self.find_predicate(predicate)
      predicate_mappings.each do |namespace,predicates|
        if predicates.fetch(predicate,nil)
          return predicates[predicate], namespace
        end
      end
      raise ActiveFedora::UnregisteredPredicateError, "Unregistered predicate: #{predicate.inspect}"
    end

  end

end
