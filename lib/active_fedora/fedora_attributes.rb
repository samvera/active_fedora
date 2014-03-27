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
      # TODO deprecate this
      id
    end

    #return the owner id
    def owner_id
      Array(@inner_object.ownerId).first
    end
    
    def owner_id=(owner_id)
      @inner_object.ownerId=(owner_id)
    end
  end
end
