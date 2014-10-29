require 'deprecation'

module ActiveFedora
  module Datastreams
    extend ActiveSupport::Concern
    extend Deprecation
    self.deprecation_horizon = 'active-fedora version 9.0'

    autoload :NokogiriDatastreams, 'active_fedora/datastreams/nokogiri_datastreams'

    included do
      class_attribute :child_resource_reflections
      self.child_resource_reflections = {}
      class << self
        def inherited_with_datastreams(kls) #:nodoc:
          ## Do some inheritance logic that doesn't override Base.inherited
          inherited_without_datastreams kls
          # each subclass should get a copy of the parent's datastream definitions, it should not add to the parent's definition table.
          kls.child_resource_reflections = kls.child_resource_reflections.dup
        end
        alias_method_chain :inherited, :datastreams
      end
    end

    def ds_specs
      child_resource_reflections
    end
    deprecation_deprecate :ds_specs

    def serialize_datastreams
      datastreams.each {|k, ds| ds.serialize! }
    end

    #
    # Datastream Management
    #

    # Returns all known datastreams for the object.  If the object has been
    # saved to fedora, the persisted datastreams will be included.
    # Datastreams that have been modified in memory are given preference over
    # the copy in Fedora.
    def datastreams
      @datastreams ||= DatastreamHash.new
    end

    def clear_datastreams
      @datastreams = nil
    end

    def configure_datastream(ds, reflection=nil)
      reflection ||= child_resource_reflections[ds.dsid]
      if reflection
        # If you called has_metadata with a block, pass the block into the Datastream class
        if reflection.options[:block].class == Proc
          reflection.options[:block].call(ds)
        end
      end
    end

    def datastream_object_for reflection, options={}
      # ds_spec is nil when called from Rubydora for existing datastreams, so it should not be autocreated
      reflection.type.new(self, reflection.name, options).tap do |ds|
        ds.default_attributes = {}
        if ds.new_record? && reflection.options[:autocreate]
          ds.datastream_will_change!
        end
      end
    end

    def datastream_from_reflection(reflection)
      datastream_object_for reflection, {load_graph: false}
    end

    def datastream_assertions
      resource.query(subject: resource, predicate: Ldp.contains).objects.map(&:to_s)
    end

    # TODO it looks like calling load_datastreams causes all the datastreams properties to load eagerly
    # Because Datastream#new triggers a load of the graph.
    def load_datastreams
      local_ds_specs = child_resource_reflections.dup
      datastream_assertions.each do |ds_uri|
        dsid = ds_uri.to_s.sub(uri + '/', '')
        reflection = local_ds_specs.delete(dsid)
        ds = reflection ? datastream_from_reflection(reflection) : Datastream.new(self, dsid)
        datastreams[dsid] = ds
        configure_datastream(datastreams[dsid])
      end
      local_ds_specs.each do |name, reflection|
        ds = datastream_from_reflection(reflection)
        add_datastream(ds)
        configure_datastream(ds, reflection)
      end
    end

    # Adds datastream to the object.
    # @return [String] dsid of the added datastream
    def add_datastream(datastream, opts={})
      datastreams[datastream.dsid] = datastream
      datastream.dsid
    end

    # @return [Array] all datastreams that return true for `metadata?` and are not Rels-ext
    def metadata_streams
      datastreams.select { |k, ds| ds.metadata? }.values
    end

    #
    # File Management
    #

    # Add the given file as a datastream in the object
    #
    # @param [File] file the file to add
    # @param [Hash] opts options: :dsid, :prefix, :mime_type
    # @option opts [String] :dsid The datastream id
    # @option opts [String] :prefix The datastream prefix (for auto-generated dsid)
    # @option opts [String] :mime_type The Mime-Type of the file
    # @option opts [String] :original_name The original name of the file (used for Content-Disposition)
    def add_file_datastream(file, opts={})
      attrs = {blob: file, prefix: opts[:prefix]}
      ds = create_datastream(self.class.datastream_class_for_name(opts[:dsid]), opts[:dsid], attrs)
      ds.mime_type = if opts[:mimeType]
        Deprecation.warn Datastreams, "The :mimeType option to add_file_datastream is deprecated and will be removed in active-fedora 9.0. Use :mime_type instead", caller
        opts[:mimeType]
      else
        opts[:mime_type]
      end
      ds.original_name = opts[:original_name] if opts.key?(:original_name)
      add_datastream(ds).tap do |dsid|
        self.class.build_datastream_accessor(dsid) unless respond_to? dsid
      end
    end


    def create_datastream(type, dsid, opts={})
      klass = type.kind_of?(Class) ? type : type.constantize
      raise ArgumentError, "Argument dsid must be of type string" if dsid && !dsid.kind_of?(String)
      ds = klass.new(self, dsid, prefix: opts[:prefix])
      ds.content = opts[:blob] || ""
      ds
    end

    module ClassMethods
      extend Deprecation
      self.deprecation_horizon = 'active-fedora version 9.0'

      def ds_specs
        child_resource_reflections
      end
      deprecation_deprecate :ds_specs

      # @param [String] dsid the datastream id
      # @return [Class] the class of the datastream
      def datastream_class_for_name(dsid)
        child_resource_reflections[dsid] ? child_resource_reflections[dsid].type : ActiveFedora::Datastream
      end

      # This method is used to specify the details of a contained resource.
      # Pass the name as the first argument and a hash of options as the second argument
      # Note that this method doesn't actually execute the block, but stores it, to be executed
      # by any the implementation of the datastream(specified as :type)
      #
      # @param [String] :name the handle to refer to this child as
      # @param [Hash] args
      # @option args [Class] :type The class that will represent this child, should extend ``Datastream''
      # @option args [String] :url
      # @option args [Boolean] :autocreate Always create this datastream on new objects
      # @yield block executed by some types of child resources
      def contains(name, args, &block)
        type = args.delete(:type)
        build_child_resource(name, type, args, &block)
      end

      # This method is used to specify the details of a datastream.
      # You can pass the name as the first argument and a hash of options as the second argument
      # or you can pass the :name as a value in the args hash. Either way, name is required.
      # Note that this method doesn't actually execute the block, but stores it, to be executed
      # by any the implementation of the datastream(specified as :type)
      #
      # @param [Hash] args
      # @option args [Class] :type The class that will represent this datastream, should extend ``Datastream''
      # @option args [String] :name the handle to refer to this datastream as
      # @option args [String] :url
      # @option args [Boolean] :autocreate Always create this datastream on new objects
      # @yield block executed by some kinds of datastreams
      def has_metadata(*args, &block)
        defaults = {
          :autocreate => false,
          :type=>nil,
          :url=>"",
        }
        if args.first.is_a? String
          name = args.first
          args = args[1] || {}
          args[:name] = name
        else
          args = args.first || {}
        end
        spec = defaults.merge(args)
        name = spec.delete(:name)
        contains(name, spec, &block)
      end
      deprecation_deprecate :has_metadata


      # @overload has_file_datastream(name, args)
      #   Declares a file datastream exists for objects of this type
      #   @param [String] name
      #   @param [Hash] args
      #     @option args :type (ActiveFedora::Datastream) The class the datastream should have
      #     @option args [Boolean] :autocreate Always create this datastream on new objects
      # @overload has_file_datastream(args)
      #   Declares a file datastream exists for objects of this type
      #   @param [Hash] args
      #     @option args :name ("content") The dsid of the datastream
      #     @option args :type (ActiveFedora::Datastream) The class the datastream should have
      #     @option args [Boolean] :autocreate Always create this datastream on new objects
      def has_file_datastream(*args)
        if args.first.is_a? String
          name = args.first
          args = args[1] || {}
          args[:name] = name
        else
          args = args.first || {}
        end
        spec = { type: ActiveFedora::Datastream }.merge(args)
        name = spec.delete(:name)
        contains(name, spec)
      end
      deprecation_deprecate :has_file_datastream

      def build_datastream_accessor(dsid)
        name = name_for_dsid(dsid)
        define_method name do
          datastreams[dsid]
        end
      end


      private

        # Creates a datastream spec combining the given args and default values
        # @param [String] name  handl of the resource
        # @param [Hash] args
        # @param defaults [Hash] the default values for the datastream spec
        # @yield block executed by some kinds of datastreams
        def build_child_resource(name, type, args, &block)
          args[:block] = block if block
          child_resource_reflections[name]= ChildResourceReflection.new(name, type, args)
          build_datastream_accessor(name)
        end

        ## Given a dsid return a standard name
        def name_for_dsid(dsid)
          dsid.gsub('-', '_')
        end

    end

    class ChildResourceReflection
      attr_reader :name, :type, :options
      def initialize(name, type, options)
        raise ArgumentError, "You must provide a name (dsid) for the datastream" unless name
        raise ArgumentError, "You must provide a :type property for the datastream '#{name}'" unless type
        @name = name
        @type = type
        @options = options
      end
    end

  end
end
