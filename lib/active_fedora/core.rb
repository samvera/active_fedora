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
      # Accepts a proc that takes a pid and transforms it to a URI
      mattr_accessor :translate_id_to_uri, instance_writer: false

      ##
      # :singleton-method
      #
      # Accepts a proc that takes a uri and transforms it to a pid
      mattr_accessor :translate_uri_to_id, instance_writer: false
    end

    # Constructor.  You may supply a custom +:pid+, or we call the Fedora Rest API for the
    # next available Fedora pid, and mark as new object.
    # Also, if +attrs+ does not contain +:pid+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next pid available within
    # the given namespace.
    def initialize(attributes_or_resource_or_url = nil)
      case attributes_or_resource_or_url
        when Ldp::Resource
          super
        when String
          super(self.class.id_to_uri(attributes_or_resource_or_url))
        when Hash
          attributes = attributes_or_resource_or_url
          pid = attributes.delete(:pid)
          pid ? super(self.class.id_to_uri(pid)) : super()
        when NilClass
          super
        else
          raise ArgumentError
      end

      @association_cache = {}
      load_datastreams
      self.attributes = attributes if attributes
      run_callbacks :initialize
    end

    # Reloads the object from Fedora.
    def reload
      raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that hasn't been saved" unless persisted?
      clear_association_cache
      clear_datastreams
      super
      load_datastreams
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
    def init_with_resource(resource)
      init_core(resource)
      @association_cache = {}
      load_datastreams
      run_callbacks :find
      run_callbacks :initialize
      self
    end

    def ==(comparison_object)
         comparison_object.equal?(self) ||
           (comparison_object.instance_of?(self.class) &&
             comparison_object.pid == pid &&
             !comparison_object.new_record?)
    end

    def freeze
      @attributes = @attributes.clone.freeze
      datastreams.freeze
      self
    end

    def frozen?
      datastreams.frozen?
    end

    module ClassMethods
      # Returns a suitable uri object for :has_model
      # Should reverse Model#from_class_uri
      # TODO this is a poorly named method
      def to_class_uri(attrs = {})
        self.name
      end

      ##
      # Transforms a pid into a uri
      # if translate_id_to_uri is set it uses that proc, otherwise just the default
      def id_to_uri(id)
        if translate_id_to_uri
          translate_id_to_uri.call(id)
        else
          super
        end
      end

      ##
      # Transforms a uri into a pid
      # if translate_uri_to_id is set it uses that proc, otherwise just the default
      def uri_to_id(uri)
        if translate_uri_to_id
          translate_uri_to_id.call(uri)
        else
          super
        end
      end

      private

      def relation
        Relation.new(self)
      end
    end
  end
end
