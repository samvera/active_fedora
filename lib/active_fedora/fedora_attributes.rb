module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern

    included do
      attribute :has_model, [ RDF::URI.new("http://fedora.info/definitions/v4/rels-ext#hasModel"), FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
      attribute :datastream_assertions, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#hasChild") ]

      # TODO is it possible to put defaults here?
      attribute :create_date, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#created"), FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
      attribute :modified_date, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#lastModified"), FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
    end


    def pid
      # TODO deprecate this
      id
    end

  end
end
