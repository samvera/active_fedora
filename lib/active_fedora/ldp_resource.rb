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

    # Don't dump @client, it has a proc and thus can't be serialized.
    def marshal_dump
      (instance_variables - [:@client]).map { |name| [name, instance_variable_get(name)] }
    end

    def marshal_load(data)
      ivars = data
      ivars.each { |name, val| instance_variable_set(name, val) }
    end
  end
end
