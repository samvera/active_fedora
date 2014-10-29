module ActiveFedora
  module Versionable
    extend ActiveSupport::Concern

    included do
      class_attribute :versionable
    end

    module ClassMethods
      def has_many_versions
        self.versionable = true
      end
    end

    # TODO: This only applies to objects. If we want the same for child resources, it would need to go
    # under fcr:metadata
    def model_type
      resource.query(subject: resource.rdf_subject, predicate: RDF.type).objects
    end

    def versions
      results = versions_graph.query([nil, RDF::URI.new('http://fedora.info/definitions/v4/repository#hasVersionLabel'), nil])
      results.map(&:object)
    end

    def versions_graph
      @versions_graph ||= RDF::Graph.new << RDF::Reader.for(:ttl).new(versions_request)
    end

    def versions_url
      uri + '/fcr:versions'
    end

    def create_version
      resp = ActiveFedora.fedora.connection.post(versions_url, nil, {slug: version_name})
      @versions_graph = nil
      reload
      resp.success?
    end

    def restore_version label
      resp = ActiveFedora.fedora.connection.patch(version_url(label), nil)
      @versions_graph = nil
      reload
      refresh_attributes if self.respond_to?("refresh_attributes")
      resp.success?
    end

    private

      def versions_request
        resp = begin
          ActiveFedora.fedora.connection.get(versions_url)
        rescue Ldp::NotFound
          return ''
        end
        if !resp.success?
          raise "unexpected return value #{resp.status} for when getting datastream content at #{uri}\n\t#{resp.body}"
        elsif resp.headers['content-type'] != 'text/turtle'
          raise "unknown response format. got '#{resp.headers['content-type']}', but was expecting 'text/turtle'"
        end
        resp.body
      end

      def version_url label
        versions_url + '/' + label
      end

      def version_name
        if versions.empty?
          "version1"
        else
          "version" + (versions.count + 1).to_s
        end
      end

  end
end
