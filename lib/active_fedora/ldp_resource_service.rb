# frozen_string_literal: true
module ActiveFedora
  class LdpResourceService
    attr_reader :connection

    def initialize(conn)
      @connection = conn
    end

    def build(klass, id)
      if id
        parsed_fedora_host = URI.parse(ActiveFedora.fedora.host).to_s
        segments = id.gsub(parsed_fedora_host, '')
        relative_id = segments.gsub(ActiveFedora.fedora.base_path, '')

        LdpResource.new(connection, to_uri(klass, relative_id))
      else
        # Update ActiveFedora::Persistence
        # self.identifier_service_class = NullIdentifierService
        parent_uri = ActiveFedora.fedora.host + ActiveFedora.fedora.base_path
        node_id = SecureRandom.uuid
        node_uri = "#{parent_uri}/#{node_id}"

        #LdpResource.new(connection, node_uri, nil, parent_uri)
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
