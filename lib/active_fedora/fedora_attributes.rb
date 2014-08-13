module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern
    include Rdf::Identifiable

    included do
      extend ActiveTriples::Properties
      delegate :rdf_subject, :set_value, :get_values, to: :resource


      property :has_model, predicate: RDF::URI.new("http://fedora.info/definitions/v4/rels-ext#hasModel")
      # attribute :has_model, [ RDF::URI.new("http://fedora.info/definitions/v4/rels-ext#hasModel"), FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
      property :datastream_assertions, predicate: ActiveFedora::Rdf::Fcrepo.hasChild
      # attribute :datastream_assertions, [ ActiveFedora::Rdf::Fcrepo.hasChild ]

      # # TODO is it possible to put defaults here?
      # attribute :create_date, [ ActiveFedora::Rdf::Fcrepo.created, FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
      property :create_date, predicate: ActiveFedora::Rdf::Fcrepo.created
      # attribute :modified_date, [ ActiveFedora::Rdf::Fcrepo.lastModified, FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string ]
      property :modified_date, predicate: ActiveFedora::Rdf::Fcrepo.lastModified
    end

    def id
      self.class.uri_to_id(URI.parse(uri)) if uri.present?
    end

    alias pid id

    def uri
      @orm.try(:resource).try(:subject_uri).try(:to_s)
    end

    ##
    # The resource is the RdfResource object that stores the graph for
    # the datastream and is the central point for its relationship to
    # other nodes.
    #
    # set_value, get_value, and property accessors are delegated to this object.
    def resource
      @resource ||= begin
                      r = ActiveFedora::FedoraRdfResource.new(uri)
                      r.singleton_class.properties = self.class.properties
                      r.singleton_class.properties.keys.each do |property|
                        r.singleton_class.send(:register_property, property)
                      end
                      # r.singleton_class.accepts_nested_attributes_for(*nested_attributes_options.keys) unless nested_attributes_options.blank?
                      r << @orm.graph
                      r
                    end
    end

  end
end
