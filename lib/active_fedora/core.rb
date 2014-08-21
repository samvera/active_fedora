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

      attr_reader :orm
    end

    # Constructor.  You may supply a custom +:pid+, or we call the Fedora Rest API for the
    # next available Fedora pid, and mark as new object.
    # Also, if +attrs+ does not contain +:pid+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next pid available within
    # the given namespace.
    def initialize(attributes_or_resource_or_url = nil)
      g = RDF::Graph.new
      case attributes_or_resource_or_url
        when Ldp::Resource::RdfSource
          @orm = Ldp::Orm.new(subject_or_data)
          attributes = get_attributes_from_orm(@orm)
        when String
          @orm = Ldp::Orm.new(Ldp::Resource::RdfSource.new(conn, self.class.id_to_uri(attributes_or_resource_or_url)))
          @attributes = {}.with_indifferent_access
        when Hash
          attributes = attributes_or_resource_or_url
          pid = attributes.delete(:pid)
          attributes = attributes.with_indifferent_access if attributes
          @orm = if pid
            Ldp::Orm.new(Ldp::Resource::RdfSource.new(conn, self.class.id_to_uri(pid)))
          else
            Ldp::Orm.new(Ldp::Resource::RdfSource.new(conn, nil, g, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path))
          end
        when NilClass
          @orm = Ldp::Orm.new(Ldp::Resource::RdfSource.new(conn, nil, g, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path))
          attributes = {}.with_indifferent_access
        else
          raise ArgumentError, "#{attributes_or_resource_or_url.class} is not acceptable"

      end

      @association_cache = {}
      assert_content_model
      load_datastreams
      self.attributes = attributes if attributes
      run_callbacks :initialize
    end

    # Reloads the object from Fedora.
    def reload
      raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that hasn't been saved" unless persisted?
      clear_association_cache
      clear_datastreams
      @orm = Ldp::Orm.new(Ldp::Resource::RdfSource.new(conn, uri))
      @resource = nil
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
    def init_with_resource(rdf_resource)
      @orm = Ldp::Orm.new(rdf_resource)
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
      #@attributes = @attributes.clone.freeze
      datastreams.freeze
      self
    end

    def frozen?
      datastreams.frozen?
    end

    protected

      # This can be overriden to assert a different model
      # It's normally called once in the lifecycle, by #create#
      def assert_content_model
        self.has_model = self.class.to_s
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
          id = "/#{id}" unless id.start_with? '/'
          id = ActiveFedora.fedora.base_path + id unless id.start_with? "#{ActiveFedora.fedora.base_path}/"
          ActiveFedora.fedora.host + id
        end
      end

      ##
      # Transforms a uri into a pid
      # if translate_uri_to_id is set it uses that proc, otherwise just the default
      def uri_to_id(uri)
        if translate_uri_to_id
          translate_uri_to_id.call(uri)
        else
          id = uri.to_s.sub(ActiveFedora.fedora.host + ActiveFedora.fedora.base_path, '')
          id.start_with?('/') ? id[1..-1] : id
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

  end
end
