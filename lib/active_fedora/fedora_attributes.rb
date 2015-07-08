module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern
    include InheritableAccessors

    included do
      include ActiveTriples::Properties
      include ActiveTriples::Reflection

      # get_values() is called by ActiveTriples in the PropertyBuilder
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


    ##
    # The resource is the RdfResource object that stores the graph for
    # the datastream and is the central point for its relationship to
    # other nodes.
    #
    # set_value, get_value, and property accessors are delegated to this object.
    def resource
      # Appending the graph at the end is necessary because adding it as the
      # parent leaves behind triples not related to the ldp_source's rdf
      # subject.
      @resource ||= self.class.resource_class.new(@ldp_source.graph.rdf_subject, @ldp_source.graph) << @ldp_source.graph
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
