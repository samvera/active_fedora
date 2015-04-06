module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern
    include InheritableAccessors

    included do
      include ActiveTriples::Properties
      include ActiveTriples::Reflection
      delegate :rdf_subject, :get_values, :type, to: :resource

      property :has_model, predicate: ActiveFedora::RDF::Fcrepo::Model.hasModel
      property :create_date, predicate: ActiveFedora::RDF::Fcrepo4.created
      property :modified_date, predicate: ActiveFedora::RDF::Fcrepo4.lastModified

      def create_date
        super.first
      end

      def modified_date
        super.first
      end

      define_inheritable_accessor(:type, :rdf_label)
    end

    # Override ActiveTriples method for setting properties
    def set_value(*args)
      raise ReadOnlyRecord if readonly?
      resource.set_value(*args)
    end

    def id
      if uri.kind_of?(::RDF::URI) && uri.value.blank?
        nil
      elsif uri.present?
        self.class.uri_to_id(URI.parse(uri))
      end
    end

    def id=(id)
      raise "ID has already been set to #{self.id}" if self.id
      @ldp_source = build_ldp_resource(id.to_s)
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

    # You can set the URI to use for the rdf_label on ClassMethods.rdf_label, then on
    # the instance, calling rdf_label returns the value of that configured property
    def rdf_label
      resource.rdf_label
    end

    module ClassMethods
      # We make a unique class, because properties belong to a class.
      # This keeps properties from different objects separate.
      # Since the copy of properties can only happen once, we don't want to invoke it
      # until all properties have been defined.
      def resource_class
        @generated_resource_class ||= begin
            klass = self.const_set(:GeneratedResourceSchema, Class.new(ActiveTriples::Resource))
            klass.configure active_triple_options
            klass.properties.merge(self.properties).each do |property, config|
              klass.property(config.term,
                             predicate: config.predicate,
                             class_name: config.class_name)
            end
            klass
        end
      end

      private
        # @return a Hash of options suitable for passing to ActiveTriples::Base.configure
        def active_triple_options
          { type: type, rdf_label: rdf_label }
        end
    end
  end
end
