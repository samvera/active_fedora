module ActiveFedora
  module Core
    extend ActiveSupport::Concern

    included do
      ##
      # :singleton-method:
      #
      # Accepts a logger conforming to the interface of Log4r which can be
      # retrieved on both a class and instance level by calling +logger+.
      mattr_accessor :logger, instance_writer: false

      ##
      # :singleton-method
      #
      # Accepts a proc that takes an id and transforms it to a URI
      mattr_accessor :translate_id_to_uri, instance_writer: false

      ##
      # :singleton-method
      #
      # Accepts a proc that takes a uri and transforms it to an id
      mattr_accessor :translate_uri_to_id, instance_writer: false

    end

    def ldp_source
      @ldp_source
    end

    # Constructor.  You may supply a custom +:id+, or we call the Fedora Rest API for the
    # next available Fedora id, and mark as new object.
    # Also, if +attrs+ does not contain +:id+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next id available within
    # the given namespace.
    def initialize(attributes_or_resource_or_url = nil)
      attributes = initialize_resource_and_attributes(attributes_or_resource_or_url)
      raise IllegalOperation, "Attempting to recreate existing ldp_source" unless @ldp_source.new?
      @association_cache = {}
      assert_content_model
      load_attached_files
      self.attributes = attributes if attributes
      run_callbacks :initialize
    end

    # Reloads the object from Fedora.
    def reload
      check_persistence unless persisted?
      clear_association_cache
      clear_attached_files
      @ldp_source = LdpResource.new(conn, uri)
      @resource = nil
      load_attached_files
      self
    end

    # Initialize an empty model object and set its +resource+
    # example:
    #
    #   class Post < ActiveFedora::Base
    #   end
    #
    #   post = Post.allocate
    #   post.init_with_resource(Ldp::Resource.new('http://example.com/post/1'))
    #   post.title # => 'hello world'
    def init_with_resource(rdf_resource)
      @ldp_source = rdf_resource
      @association_cache = {}
      load_attached_files
      run_callbacks :find
      run_callbacks :initialize
      self
    end

    def ==(comparison_object)
         comparison_object.equal?(self) ||
           (comparison_object.instance_of?(self.class) &&
             comparison_object.id == id &&
             !comparison_object.new_record?)
    end

    def freeze
      @resource.freeze
      #@attributes = @attributes.clone.freeze
      attached_files.freeze
      self
    end

    def frozen?
      attached_files.frozen?
    end

    def to_uri(id)
      self.class.id_to_uri(id)
    end

    protected

      # This can be overriden to assert a different model
      # It's normally called once in the lifecycle, by #create#
      def assert_content_model
        self.has_model = self.class.to_s
      end

    module ClassMethods
      def generated_association_methods
        @generated_association_methods ||= begin
          mod = const_set(:GeneratedAssociationMethods, Module.new)
          include mod
          mod
        end
      end

      # Returns a suitable uri object for :has_model
      # Should reverse Model#from_class_uri
      # TODO this is a poorly named method
      def to_class_uri(attrs = {})
        name
      end

      ##
      # Transforms an id into a uri
      # if translate_id_to_uri is set it uses that proc, otherwise just the default
      def id_to_uri(id)
        if translate_id_to_uri
          translate_id_to_uri.call(id)
        else
          id = "/#{id}" unless id.start_with? '/'
          id = ActiveFedora.fedora.base_path + id unless id.start_with? "#{ActiveFedora.fedora.base_path}/"
          ActiveFedora.fedora.host + id
        end
      end

      ##
      # Transforms a uri into an id
      # if translate_uri_to_id is set it uses that proc, otherwise just the default
      def uri_to_id(uri)
        if translate_uri_to_id
          translate_uri_to_id.call(uri)
        else
          id = uri.to_s.sub(ActiveFedora.fedora.host + ActiveFedora.fedora.base_path, '')
          id.start_with?('/') ? id[1..-1] : id
        end
      end

      ##
      # Provides the common interface for ActiveTriples::Identifiable
      def from_uri(uri,_)
        begin
          self.find(uri_to_id(uri))
        rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone
          ActiveTriples::Resource.new(uri)
        end
      end

      private

      def relation
        Relation.new(self)
      end
    end

    private
      def conn
        ActiveFedora.fedora.connection
      end

      def build_ldp_resource(id=nil)
        if id
          LdpResource.new(conn, to_uri(id))
        else
          LdpResource.new(conn, nil, nil, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
        end
      end

      def check_persistence
        if destroyed?
          raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that has been destroyed"
        else
          raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that hasn't been saved"
        end
      end

      def initialize_resource_and_attributes attributes_or_resource_or_url
        case attributes_or_resource_or_url
          when String
            @ldp_source = build_ldp_resource(attributes_or_resource_or_url)
            @attributes = {}.with_indifferent_access
          when Hash
            attributes = attributes_or_resource_or_url

            id = attributes.delete(:id)

            # TODO: Remove when we decide using 'pid' is no longer supported.
            if !id && attributes.has_key?(:pid)
              Deprecation.warn Core, 'Initializing with :pid is deprecated and will be removed in active-fedora 9.0. Use :id instead'
              id = attributes.delete(:pid)
            end

            attributes = attributes.with_indifferent_access if attributes
            @ldp_source = if id
              build_ldp_resource(id)
            else
              build_ldp_resource
            end
          when NilClass
            @ldp_source = build_ldp_resource
            attributes = {}.with_indifferent_access
          else
            raise ArgumentError, "#{attributes_or_resource_or_url.class} is not acceptable"
        end
        return attributes
      end

  end
end
