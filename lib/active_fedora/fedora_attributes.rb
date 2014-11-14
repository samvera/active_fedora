module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern

    included do
      include Rdf::Indexing
      include ActiveTriples::Properties
      include ActiveTriples::Reflection
      delegate :rdf_subject,  :get_values, to: :resource

      property :has_model, predicate: RDF::URI.new("http://fedora.info/definitions/v4/rels-ext#hasModel")
      property :create_date, predicate: ActiveFedora::Rdf::Fcrepo.created
      property :modified_date, predicate: ActiveFedora::Rdf::Fcrepo.lastModified

      def create_date
        super.first
      end

      def modified_date
        super.first
      end
    end

    # Override ActiveTriples method for setting properties
    def set_value(*args)
      raise ReadOnlyRecord if readonly?
      resource.set_value(*args)
    end

    def id
      if uri.kind_of?(RDF::URI) && uri.value.blank?
        nil
      elsif uri.present?
        self.class.uri_to_id(URI.parse(uri))
      end
    end

    # TODO: Remove after we no longer support #pid.
    def pid
      Deprecation.warn FedoraAttributes, "#{self.class}#pid is deprecated and will be removed in active-fedora 10.0. Use #{self.class}#id instead."
      id
    end

    def uri
      # TODO could we return a RDF::URI instead?
      uri = @ldp_source.try(:subject_uri)
      uri.value == '' ? uri : uri.to_s
    end

    ##
    # The resource is the RdfResource object that stores the graph for
    # the datastream and is the central point for its relationship to
    # other nodes.
    #
    # set_value, get_value, and property accessors are delegated to this object.
    def resource
      @resource ||= self.class.resource_class.new(@ldp_source.graph.rdf_subject, @ldp_source.graph)
    end

    module ClassMethods
      # We make a unique class, because properties belong to a class.
      # This keeps properties from different objects separate.
      def resource_class
        @generated_resource_class ||= begin
            klass = self.const_set(:GeneratedResourceSchema, Class.new(ActiveTriples::Resource))
            klass.properties.merge(self.properties).each do |property, config|
              klass.property(config.term,
                             predicate: config.predicate,
                             class_name: config.class_name,
                             multivalue: config.multivalue)
            end
            klass
        end
      end
    end
  end
end
