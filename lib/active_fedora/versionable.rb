module ActiveFedora
  module Versionable
    extend ActiveSupport::Concern

    included do
      class_attribute :versionable
    end

    # Returns an array of ActiveFedora::VersionsGraph::ResourceVersion objects.
    def versions(reload = false)
      response = versions_request

      return ActiveFedora::VersionsGraph.new unless response
      if reload
        @versions = ActiveFedora::VersionsGraph.new << versions_request.reader
      else
        @versions ||= ActiveFedora::VersionsGraph.new << versions_request.reader
      end
    end

    def create_version
      resp = ActiveFedora.fedora.connection.post(versions_uri, nil)
      @versions = nil
      resp.success?
    end

    # Queries Fedora to figure out if there are versions for the resource.
    def has_versions?
      resp = ActiveFedora.fedora.connection.get(versions_uri)
      graph = ::RDF::Graph.new << resp.reader
      !graph.query(predicate: ::RDF::Vocab::LDP.contains).blank?
    rescue Ldp::NotFound
      false
    end

    private

      def versions_request
        ActiveFedora.fedora.connection.get(versions_uri)
      rescue Ldp::NotFound
        false
      end

      def versions_uri
        uri + '/fcr:versions'
      end

      def status_message(response)
        "Unexpected return value #{response.status} when retrieving datastream content at #{uri}\n\t#{response.body}"
      end

      def bad_headers(response)
        "Unknown response format. Got '#{response.headers['content-type']}', but was expecting 'text/turtle'"
      end
  end
end
