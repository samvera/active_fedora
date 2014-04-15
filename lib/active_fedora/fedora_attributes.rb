module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern

    included do
      attribute :has_model, [ RDF::URI.new("info:fedora/fedora-system:def/relations-external#hasModel")]
      # TODO is it possible to put defaults here?
      attribute :create_date, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#created"), FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
      attribute :modified_date, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#lastModified"), FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
    end


    def pid
      id
    end

  end
end
