module ActiveFedora
  class FixityService
    extend ActiveSupport::Concern

    attr_accessor :target, :response

    # @param [String, RDF::URI] target url for a Fedora resource
    def initialize(target)
      raise ArgumentError, 'You must provide a uri' unless target
      @target = target.to_s
    end

    # Executes a fixity check on Fedora and saves the Faraday::Response.
    # @return true or false
    def check
      @response = fixity_response_from_fedora
      status.include?(success)
    end

    def status
      fixity_graph.query(predicate: premis_status_predicate).map(&:object) +
        fixity_graph.query(predicate: fedora_status_predicate).map(&:object)
    end

    private

      def premis_status_predicate
        ::RDF::Vocab::PREMIS.hasEventOutcome
      end

      # Fcrepo4.status was used by Fedora < 4.3, but it was removed
      # from the 2015-07-24 version of the fedora 4 ontology
      # http://fedora.info/definitions/v4/2015/07/24/repository and
      # from rdf-vocab in version 0.8.5
      def fedora_status_predicate
        ::RDF::URI("http://fedora.info/definitions/v4/repository#status")
      end

      def success
        ::RDF::Literal.new("SUCCESS")
      end

      def fixity_response_from_fedora
        uri = target + "/fcr:fixity"
        ActiveFedora.fedora.connection.get(encoded_url(uri))
      end

      def fixity_graph
        ::RDF::Graph.new << ::RDF::Reader.for(:ttl).new(response.body)
      end

      # See https://jira.duraspace.org/browse/FCREPO-1247
      # @param [String] uri
      def encoded_url(uri)
        if uri =~ /fcr:versions/
          uri.gsub(/fcr:versions/, "fcr%3aversions")
        else
          uri
        end
      end
  end
end
