module ActiveFedora
  module Versionable
    extend ActiveSupport::Concern

    included do
      class_attribute :versionable
      attribute :model_type, [ RDF.type ]

    end

    module ClassMethods
      def has_many_versions
        self.versionable = true
      end
    end

    def versions
      # puts "Versions #{versions_graph.dump(:ttl)}"
      results = versions_graph.query([rdf_subject, RDF::URI.new('http://fedora.info/definitions/v4/repository#hasVersion'), nil])
      results.map(&:object)
    end

    def create_version
      resp = orm.resource.client.post(versions_url)
      resp.success?
    end

    # for datastreams
    def save(*)
      assert_versionable if versionable
      super
    end

    private

      def rdf_subject
        RDF::URI.new uri
      end

      def versions_graph
        @versions_graph ||= RDF::Graph.new << RDF::Reader.for(:ttl).new(versions_request)
      end

      def versions_request
        resp = orm.resource.client.get(versions_url)
        if !resp.success?
          raise "unexpected return value #{resp.status} for when getting datastream content at #{uri}\n\t#{resp.body}"
        elsif resp.headers['content-type'] != 'text/turtle'
          raise "unknown response format. got '#{resp.headers['content-type']}', but was expecting 'text/turtle'"
        end
        resp.body
      end

      def versions_url
        uri + '/fcr:versions'
      end

      def assert_versionable
        self.model_type ||= []
        self.model_type += [RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable')]
      end

  end
end
