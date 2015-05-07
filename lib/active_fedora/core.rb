module ActiveFedora
  module Core
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern

    autoload :FedoraIdTranslator
    autoload :FedoraUriTranslator

    included do
      ##
      # :singleton-method:
      #
      # Accepts a logger conforming to the interface of Log4r which can be
      # retrieved on both a class and instance level by calling +logger+.
      mattr_accessor :logger, instance_writer: false
    end

    def ldp_source
      @ldp_source
    end

    # Constructor.  You may supply a custom +:id+, or we call the Fedora Rest API for the
    # next available Fedora id, and mark as new object.
    # Also, if +attrs+ does not contain +:id+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next id available within
    # the given namespace.
    def initialize(attributes_or_id = nil, &block)
      init_internals
      attributes = initialize_attributes(attributes_or_id)
      @ldp_source = build_ldp_resource(attributes.delete(:id))
      raise IllegalOperation, "Attempting to recreate existing ldp_source: `#{ldp_source.subject}'" unless ldp_source.new?
      assert_content_model
      load_attached_files
      self.attributes = attributes

      yield self if block_given?
      run_callbacks :initialize
    end

    # Reloads the object from Fedora.
    def reload
      check_persistence unless persisted?
      clear_association_cache
      clear_attached_files
      refresh
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
      init_internals
      @ldp_source = rdf_resource
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

    # Returns +true+ if the record is read only. Records loaded through joins with piggy-back
    # attributes will be marked as read only since they cannot be saved.
    def readonly?
      @readonly
    end

    # Marks this record as read only.
    def readonly!
      @readonly = true
    end

    protected

      # This can be overriden to assert a different model
      # It's normally called once in the lifecycle, by #create#
      def assert_content_model
        self.has_model = self.class.to_s
      end

    module ClassMethods

      SLASH = '/'.freeze

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

      private

      def relation
        Relation.new(self)
      end
    end

    private

      def init_internals
        @resource          = nil
        @readonly          = false
        @association_cache = {}
      end

      def build_ldp_resource(id=nil)
        ActiveFedora.fedora.ldp_resource_service.build(self.class, id)
      end

      def check_persistence
        if destroyed?
          raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that has been destroyed"
        else
          raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that hasn't been saved"
        end
      end

      def initialize_attributes attributes_or_id
        case attributes_or_id
          when String
            attributes = {id: attributes_or_id}.with_indifferent_access
          when Hash
            attributes = attributes_or_id.with_indifferent_access
            # TODO: Remove when we decide using 'pid' is no longer supported.
            if !attributes.key?(:id) && attributes.key?(:pid)
              Deprecation.warn Core, 'Initializing with :pid is deprecated and will be removed in active-fedora 10.0. Use :id instead'
              attributes[:id] = attributes.delete(:pid)
            end

          when NilClass
            attributes = {}.with_indifferent_access
          else
            raise ArgumentError, "#{attributes_or_id.class} is not acceptable"
        end
        return attributes
      end

  end
end
