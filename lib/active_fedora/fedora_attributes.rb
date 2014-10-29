module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern
    include Rdf::Identifiable

    included do
      include Rdf::Indexing
      extend ActiveTriples::Properties
      delegate :rdf_subject,  :get_values, to: :resource

      property :has_model, predicate: RDF::URI.new("http://fedora.info/definitions/v4/rels-ext#hasModel")
      property :create_date, predicate: ActiveFedora::Rdf::Fcrepo.created
      property :modified_date, predicate: ActiveFedora::Rdf::Fcrepo.lastModified

      # Hack until https://github.com/no-reply/ActiveTriples/pull/37 is merged
      def create_date_with_first
        create_date_without_first.first
      end
      alias_method_chain :create_date, :first

      # Hack until https://github.com/no-reply/ActiveTriples/pull/37 is merged
      def modified_date_with_first
        modified_date_without_first.first
      end
      alias_method_chain :modified_date, :first
    end

    def set_value(*args)
      resource.set_value(*args)
    end

    def id
      if uri.kind_of?(RDF::URI) && uri.value.blank?
        nil
      elsif uri.present?
        self.class.uri_to_id(URI.parse(uri))
      end
    end

    alias pid id

    def uri
      # TODO could we return a RDF::URI instead?
      uri = @orm.try(:resource).try(:subject_uri)
      uri.value == '' ? uri : uri.to_s
    end

    ##
    # The resource is the RdfResource object that stores the graph for
    # the datastream and is the central point for its relationship to
    # other nodes.
    #
    # set_value, get_value, and property accessors are delegated to this object.
    def resource
      @resource ||= begin
                      r = @orm.graph
                      r.singleton_class.properties = self.class.properties
                      r.singleton_class.properties.keys.each do |property|
                        r.singleton_class.send(:register_property, property)
                      end
                      # r.singleton_class.accepts_nested_attributes_for(*nested_attributes_options.keys) unless nested_attributes_options.blank?
                      r
                    end
    end

  end
end
