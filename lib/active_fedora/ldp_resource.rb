module ActiveFedora
  class LdpResource < Ldp::Resource::RdfSource
    def build_empty_graph
      graph_class.new(subject_uri)
    end

    def self.graph_class
      ActiveTriples::Resource
    end

    def graph_class
      self.class.graph_class
    end

    ##
    # @param [RDF::Graph] original_graph The graph returned by the LDP server
    # @return [RDF::Graph] A graph striped of any inlined resources present in the original
    def build_graph(original_graph)
      inlined_resources = get.graph.query(predicate: Ldp.contains).map { |x| x.object }

      # ActiveFedora always wants to copy the resources to a new graph because it
      # forces a cast to FedoraRdfResource
      graph_without_inlined_resources(original_graph, inlined_resources)
    end

    # Don't dump @client, it has a proc and thus can't be serialized.
    def marshal_dump
      ivars = (instance_variables - [:@client]).map { |name| [name, instance_variable_get(name)] }
    end

    def marshal_load(data)
      ivars = data
      ivars.each { |name, val| instance_variable_set(name, val) }
    end
  end
end
