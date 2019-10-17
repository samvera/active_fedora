module ActiveFedora
  module LdpResourceAddons
    extend ActiveSupport::Concern
    module ClassMethods
      def graph_class
        ActiveTriples::Resource
      end
    end

    def build_empty_graph
      graph_class.new(subject_uri)
    end

    def graph_class
      self.class.graph_class
    end

    # Don't dump @client, it has a proc and thus can't be serialized.
    def marshal_dump
      (instance_variables - [:@client]).map { |name| [name, instance_variable_get(name)] }
    end

    def marshal_load(data)
      data.each { |name, val| instance_variable_set(name, val) }
    end
  end
  class LdpResource < Ldp::Resource::RdfSource
    include LdpResourceAddons
  end
  class IndirectContainerResource < Ldp::Container::Indirect
    include LdpResourceAddons
  end
  class DirectContainerResource < Ldp::Container::Direct
    include LdpResourceAddons
  end
end
