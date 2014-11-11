require 'deprecation'

module ActiveFedora
  module AttachedFiles
    extend ActiveSupport::Concern
    extend Deprecation
    self.deprecation_horizon = "active-fedora 9.0"

    def ds_specs
      self.class.child_resource_reflections
    end
    deprecation_deprecate :ds_specs

    def serialize_attached_files
      attached_files.each {|k, ds| ds.serialize! }
    end

    #
    # Attached file management
    #

    # Returns all known attached files for the object.  If the object has been
    # saved to fedora, the persisted files will be included.
    # Attached files that have been modified in memory are given preference over
    # the copy in Fedora.
    def attached_files
      @attached_files ||= FilesHash.new
    end

    def datastreams
      attached_files
    end
    deprecation_deprecate :datastreams

    def clear_attached_files
      @attached_files = nil
    end

    def clear_datastreams
      clear_attached_files
    end
    deprecation_deprecate :clear_datastreams

    def configure_datastream(ds, reflection)
      return unless reflection
      # If you called has_metadata with a block, pass the block into the File class
      if reflection.options[:block].class == Proc
        reflection.options[:block].call(ds)
      end
    end

    def datastream_assertions
      resource.query(subject: resource, predicate: Ldp.contains).objects.map(&:to_s)
    end

    # TODO it looks like calling load_attached_files causes all the attached_files properties to load eagerly
    # Because File#new triggers a load of the graph.
    def load_attached_files
      local_ds_specs = self.class.child_resource_reflections.dup
      datastream_assertions.each do |ds_uri|
        dsid = ds_uri.to_s.sub(uri + '/', '')
        reflection = local_ds_specs.delete(dsid)
        ds = reflection ? reflection.build_datastream(self) : ActiveFedora::File.new(self, dsid)
        attach_file(ds, dsid)
        configure_datastream(attached_files[dsid], reflection)
      end
      local_ds_specs.each do |name, reflection|
        ds = reflection.build_datastream(self)
        attach_file(ds, name)
        configure_datastream(ds, reflection)
      end
    end

    # Adds datastream to the object.
    # @return [String] dsid of the added datastream
    def attach_file(file, dsid, opts={})
      attached_files[dsid] = file
      dsid
    end

    def add_datastream(datastream, opts={})
      attach_file(datastream, opts)
    end
    deprecation_deprecate :add_datastream

    # @return [Array] all attached files that return true for `metadata?` and are not Rels-ext
    def metadata_streams
      attached_files.select { |k, ds| ds.metadata? }.values
    end

    #
    # File Management
    #

    # Attach the given file to object
    #
    # @param [File] file the file to add
    # @param [Hash] opts options: :dsid, :prefix, :mime_type
    # @option opts [String] :dsid The datastream id
    # @option opts [String] :prefix The datastream prefix (for auto-generated dsid)
    # @option opts [String] :mime_type The Mime-Type of the file
    # @option opts [String] :original_name The original name of the file (used for Content-Disposition)
    def add_file_datastream(file, opts={})
      attrs = {blob: file, prefix: opts[:prefix]}
      file_path = FilePathBuilder.build(self, opts[:dsid], opts[:prefix])
      ds = create_datastream(self.class.datastream_class_for_name(file_path), file_path, attrs)
      ds.mime_type = if opts[:mimeType]
        Deprecation.warn AttachedFiles, "The :mimeType option to add_file_datastream is deprecated and will be removed in active-fedora 9.0. Use :mime_type instead", caller
        opts[:mimeType]
      else
        opts[:mime_type]
      end
      ds.original_name = opts[:original_name] if opts.key?(:original_name)
      attach_file(ds, file_path)
      self.class.build_datastream_accessor(file_path) unless respond_to? file_path
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
        reflection = reflect_on_association(dsid)
        reflection ? reflection.klass : ActiveFedora::File
      end

      # This method is used to specify the details of a contained resource.
      # Pass the name as the first argument and a hash of options as the second argument
      # Note that this method doesn't actually execute the block, but stores it, to be executed
      # by any the implementation of the datastream(specified as :class_name)
      #
      # @param [String] :name the handle to refer to this child as
      # @param [Hash] options
      # @option options [Class] :class_name The class that will represent this child, should extend ``ActiveFedora::File''
      # @option options [String] :url
      # @option options [Boolean] :autocreate Always create this datastream on new objects
      # @yield block executed by some types of child resources
      def contains(name, options = {}, &block)
        options[:block] = block if block
        create_reflection(:child_resource, name, options, self)
        build_datastream_accessor(name)
      end

      # This method is used to specify the details of a datastream.
      # You can pass the name as the first argument and a hash of options as the second argument
      # or you can pass the :name as a value in the args hash. Either way, name is required.
      # Note that this method doesn't actually execute the block, but stores it, to be executed
      # by any the implementation of the datastream(specified as :type)
      #
      # @param [Hash] args
      # @option args [Class] :type The class that will represent this datastream, should extend ``ActiveFedora::File''
      # @option args [String] :name the handle to refer to this datastream as
      # @option args [String] :url
      # @option args [Boolean] :autocreate Always create this datastream on new objects
      # @yield block executed by some kinds of datastreams
      def has_metadata(*args, &block)
        if args.first.is_a? String
          name = args.first
          args = args[1] || {}
          args[:name] = name
        else
          args = args.first || {}
        end
        name = args.delete(:name)
        args[:class_name] = args.delete(:type)
        raise ArgumentError, "You must provide a :type property for the datastream '#{name}'" unless args[:class_name]
        contains(name, args, &block)
      end
      deprecation_deprecate :has_metadata


      # @overload has_file_datastream(name, args)
      #   Declares a file datastream exists for objects of this type
      #   @param [String] name
      #   @param [Hash] args
      #     @option args :type (ActiveFedora::File) The class the datastream should have
      #     @option args [Boolean] :autocreate Always create this datastream on new objects
      # @overload has_file_datastream(args)
      #   Declares a file datastream exists for objects of this type
      #   @param [Hash] args
      #     @option args :name ("content") The dsid of the datastream
      #     @option args :type (ActiveFedora::File) The class the datastream should have
      #     @option args [Boolean] :autocreate Always create this datastream on new objects
      def has_file_datastream(*args)
        if args.first.is_a? String
          name = args.first
          args = args[1] || {}
          args[:name] = name
        else
          args = args.first || {}
        end
        name = args.delete(:name)
        args[:class_name] = args.delete(:type)
        contains(name, args)
      end
      deprecation_deprecate :has_file_datastream

      def build_datastream_accessor(dsid)
        name = name_for_dsid(dsid)
        define_method name do
          attached_files[dsid]
        end
      end

      private

        ## Given a dsid return a standard name
        def name_for_dsid(dsid)
          dsid.gsub('-', '_')
        end

    end
  end
end
