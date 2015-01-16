module ActiveFedora
  class FixityService
    extend ActiveSupport::Concern

    attr_accessor :target, :response

    # Accepts an Fedora resource such as File.ldp_resource.subject
    def initialize target
      raise ArgumentError, 'You must provide a uri' unless target
      @target = target
    end

    # Executes a fixity check on Fedora and saves the Faraday::Response.
    # Returns true when the fixity check was successfully.
    def check
      @response = get_fixity_response_from_fedora
      status.match("SUCCESS") ? true : false
    end

    def status
      fixity_graph.query(predicate: ActiveFedora::RDF::Fcrepo4.status).map(&:object).first.to_s
    end

    private

    def get_fixity_response_from_fedora
      uri = target + "/fcr:fixity"
      ActiveFedora.fedora.connection.get(encoded_url(uri))
    end

    def fixity_graph
      ::RDF::Graph.new << ::RDF::Reader.for(:ttl).new(response.body)
    end

    # See https://jira.duraspace.org/browse/FCREPO-1247
    def encoded_url uri
      if uri.match("fcr:versions")
        uri.gsub(/fcr:versions/,"fcr%3aversions")
      else
        uri
      end
    end

  end
end
