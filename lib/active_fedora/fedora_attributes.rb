module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern

    included do
      attribute :has_model, [ RDF::URI.new("info:fedora/fedora-system:def/relations-external#hasModel")]
      # TODO is it possible to put defaults here?
      attribute :create_date, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#created")]
      attribute :modified_date, [ RDF::URI.new("http://fedora.info/definitions/v4/repository#lastModified")]
    end


    def pid
      id
    end

  end
end
