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
      fixity_graph.query(predicate: status_url).map(&:object).first.to_s
    end

    private

    def get_fixity_response_from_fedora
      uri = target + "/fcr:fixity"
      ActiveFedora.fedora.connection.get(uri)
    end

    def fixity_graph
      ::RDF::Graph.new << ::RDF::Reader.for(:ttl).new(response.body)
    end

    def status_url
      ::RDF::URI("http://fedora.info/definitions/v4/repository#status")
    end

  end
end
