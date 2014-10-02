module ActiveFedora
  module FedoraAttributes
    extend ActiveSupport::Concern
    include Rdf::Identifiable

    included do
      include Rdf::Indexing
      include ActiveTriples::Properties
      include ActiveTriples::Reflection

      delegate :rdf_subject, :set_value, :get_values, to: :resource

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

    ##
    # @param [Class] an object to set as the resource class, Must be a descendant of 
    # ActiveTriples::Resource and include ActiveFedora::Rdf::Persistence.
    #
    # @return [Class] the object resource class
    def resource_class(klass=nil)
      if klass
        raise ArgumentError, "#{self} already has a resource_class #{@resource_class}, cannot redefine it to #{klass}" if @resource_class and klass != @resource_class
        raise ArgumentError, "#{klass} must be a subclass of ActiveTriples::Resource" unless klass < ActiveTriples::Resource
      end
      
      @resource_class ||= begin
                            klass = Class.new(klass || ActiveTriples::Resource)
                            klass.send(:include, Rdf::Persistence)
                            klass
                          end
    end

    def digital_object=(new_object)
      #super
      #byebug
      resource.set_subject!(self.uri) if resource.rdf_subject.value.blank?
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
    # the object resource and is the central point for its relationship to
    # other nodes.
    #
    # set_value, get_value, and property accessors are delegated to this object.
    def resource
      @resource ||= begin
                      klass = self.resource_class
                      klass.properties.each do |prop, config|
                        klass.property(config.term, 
                                       predicate: config.predicate, 
                                       class_name: config.class_name, 
                                       multivalue: config.multivalue)
                      end
                      klass.accepts_nested_attributes_for(*nested_attributes_options.keys) unless nested_attributes_options.blank?
                      #byebug
                      #uri_stub = digital_object ? self.rdf_subject.call(self) : nil
                      #uri_stub = resource.set_subject!(self.uri)

                      r = klass.new(self.uri)
                      r.datastream = self
                      r << deserialize
                      r
                    end
    end

    def serialize
      resource.set_subject!(digital_object.uri) if digital_object.id and rdf_subject.node?
      resource.dump serialization_format
    end

    def deserialize(data=nil)
      return RDF::Graph.new if new_record? && data.nil?
      data ||= datastream_content

      # Because datastream_content can return nil, we should check that here.
      return RDF::Graph.new if data.nil?

      data.force_encoding('utf-8')
      RDF::Graph.new << RDF::Reader.for(serialization_format).new(data)
    end

  end
end
