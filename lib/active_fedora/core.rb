module ActiveFedora
  module Core
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern
    include ActiveFedora::Common

    autoload :FedoraIdTranslator
    autoload :FedoraUriTranslator

    included do
      mattr_accessor :belongs_to_required_by_default, instance_accessor: false

      # Accepts a logger conforming to the interface of Log4r which can be
      # retrieved on both a class and instance level by calling +logger+.
      class_attribute :logger

      # Use NullLogger as the default and all messages sent to it are retuned as nil
      self.logger = ActiveFedora::NullLogger.new

      # All instances default to the class-level logger
      def logger
        self.class.logger
      end
    end

    # Constructor.  You may supply a custom +:id+, or we call the Fedora Rest API for the
    # next available Fedora id, and mark as new object.
    # Also, if +attrs+ does not contain +:id+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next id available within
    # the given namespace.
    def initialize(attributes = nil, &_block)
      init_internals
      attributes = attributes.dup if attributes # can't dup nil in Ruby 2.3
      id = attributes && (attributes.delete(:id) || attributes.delete('id'))
      @ldp_source = build_ldp_resource(id)
      raise IllegalOperation, "Attempting to recreate existing ldp_source: `#{ldp_source.subject}'" unless ldp_source.new?
      assign_attributes(attributes) if attributes
      assert_content_model
      load_attached_files

      yield self if block_given?
      _run_initialize_callbacks
    end

    ##
    # @param [#to_s] uri a full fedora URI or relative ID to set this resource
    #   to.
    # @note This can only be run on an unpersisted resource.
    def uri=(uri)
      if persisted?
        raise AlreadyPersistedError, "You can not set a URI for a persisted ActiveFedora object."
      else
        @ldp_source = build_ldp_resource(self.class.uri_to_id(uri))
      end
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

    def freeze
      @resource.freeze
      # @attributes = @attributes.clone.freeze
      attached_files.freeze
      self
    end

    delegate :frozen?, to: :attached_files

    # Returns the contents of the record as a nicely formatted string.
    def inspect
      inspection = ["id: #{id.inspect}"]
      inspection += self.class.attribute_names.collect do |name|
        "#{name}: #{attribute_for_inspect(name)}" if has_attribute?(name)
      end

      "#<#{self.class} #{inspection.compact.join(', ')}>"
    end

    protected

      # This method is normally called once in the lifecycle, by #create#
      def assert_content_model
        self.has_model = self.class.to_rdf_representation
      end

      module ClassMethods
        extend Deprecation

        def generated_association_methods
          @generated_association_methods ||= begin
            mod = const_set(:GeneratedAssociationMethods, Module.new)
            include mod
            mod
          end
        end

        # Returns a suitable string representation for :has_model
        # Override this method if you want to change how this class
        # is represented in RDF.
        def to_rdf_representation
          name
        end

        # Returns a suitable string representation for :has_model
        # @deprecated use to_rdf_representation instead
        def to_class_uri(attrs = nil)
          if attrs
            Deprecation.warn ActiveFedora::Core, "to_class_uri no longer acceps an argument"
          end
          to_rdf_representation
        end
        deprecation_deprecate to_class_uri: "use 'to_rdf_representation()' instead"

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

      def build_ldp_resource(id = nil)
        ActiveFedora.fedora.ldp_resource_service.build(self.class, id)
      end

      def check_persistence
        if destroyed?
          raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that has been destroyed"
        else
          raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that hasn't been saved"
        end
      end
  end
end
