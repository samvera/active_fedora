module ActiveFedora
  # This is the base class for ldp containers, it is not an ldp:BasicContainer
  class Container < ActiveFedora::Base
    property :membership_resource, predicate: ::RDF::Vocab::LDP.membershipResource
    property :has_member_relation, predicate: ::RDF::Vocab::LDP.hasMemberRelation
    property :is_member_of_relation, predicate: ::RDF::Vocab::LDP.isMemberOfRelation
    property :contained, predicate: ::RDF::Vocab::LDP.contains

    def parent
      @parent || raise("Parent hasn't been set on #{self.class}")
    end

    def parent=(parent)
      @parent = parent
      self.membership_resource = [::RDF::URI(parent.uri)]
    end

    def mint_id
      "#{id}/#{SecureRandom.uuid}"
    end

    def self.find_or_initialize(id)
      find(id)
    rescue ActiveFedora::ObjectNotFoundError
      new(id: id)
    end

    private

      # Don't allow directly setting contained
      def contained=(*_args); end
  end
end
