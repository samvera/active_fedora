module ActiveFedora
  class LdpResourceService
    attr_reader :connection

    def initialize(conn)
      @connection = conn
    end

    def build(klass, id)
      if id
        LdpResource.new(connection, to_uri(klass, id))
      else
        parent_uri = ActiveFedora.fedora.host + ActiveFedora.fedora.base_path
        LdpResource.new(connection, nil, nil, parent_uri)
      end
    end

    def build_resource_under_path(graph, parent_uri)
      parent_uri ||= ActiveFedora.fedora.host + ActiveFedora.fedora.base_path
      LdpResource.new(connection, nil, graph, parent_uri)
    end

    def update(change_set, klass, id)
      SparqlInsert.new(change_set.changes).execute(to_uri(klass, id))
    end

    private

      def to_uri(klass, id)
        klass.id_to_uri(id)
      end
  end
end
