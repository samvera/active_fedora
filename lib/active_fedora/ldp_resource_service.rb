module ActiveFedora
  class LdpResourceService
    attr_reader :connection

    def initialize(conn)
      @connection = conn
    end

    def get(klass, id)
      if id
        LdpResource.new(connection, to_uri(klass, id))
      else
        LdpResource.new(connection, nil, nil, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
      end
    end

    private
      def to_uri(klass, id)
        klass.id_to_uri(id)
      end
  end
end
