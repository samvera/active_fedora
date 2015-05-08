require 'deprecation'

module ActiveFedora
  module AttachedFiles
    extend ActiveSupport::Concern
    extend Deprecation
    self.deprecation_horizon = "active-fedora 10.0"

    def ds_specs
      self.class.child_resource_reflections
    end
    deprecation_deprecate :ds_specs

    def serialize_attached_files
      attached_files.each_value {|file| file.serialize! }
    end

    #
    # Attached file management
    #

    # Returns all known attached files for the object.  If the object has been
    # saved to fedora, the persisted files will be included.
    # Attached files that have been modified in memory are given preference over
    # the copy in Fedora.
    def attached_files
      @attached_files ||= FilesHash.new(self)
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

    def contains_assertions
      resource.query(subject: resource, predicate: Ldp.contains).objects.map(&:to_s)
    end

    def load_attached_files
      contains_assertions.each do |file_uri|
        path = file_uri.to_s.sub(uri + '/', '')
        next if association(path.to_sym)
        create_singleton_association(path)
      end
    end

    # Add an ActiveFedora::File to the object.
    # @param [ActiveFedora::File] file
    # @param [String] file_path
    # @param [Hash] opts
    # @return [String] path of the added datastream
    def attach_file(file, file_path, opts={})
      create_singleton_association(file_path)
      attached_files[file_path] = file
      file_path
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

    def add_file_datastream(file, opts={})
      Deprecation.warn AttachedFiles, "add_file_datastream is deprecated and will be removed in active-fedora 10.0. Use add_file instead"
      add_file(file, opts)
    end

    # Attach the given stream/string to object
    #
    # @param [IO, String] file the file to add
    # @param [Hash] args options: :dsid, :prefix, :mime_type
    # @option opts [String] :path The file path
    # @option opts [String] :prefix The path prefix (for auto-generated path)
    # @option opts [String] :mime_type The Mime-Type of the file
    # @option opts [String] :original_name The original name of the file (used for Content-Disposition)
    def add_file(file, *args)
      opts = if args.size == 1
        args.first
      else
        Deprecation.warn AttachedFiles, "The second option to add_file should be a hash. Passing the file path is deprecated and will be removed in active-fedora 10.0.", caller
        { path: args[0], original_name: args[1], mime_type: args[2] }
      end

      if opts[:dsid]
        Deprecation.warn AttachedFiles, "The :dsid option to add_file is deprecated and will be removed in active-fedora 10.0. Use :path instead", caller
        opts[:path] = opts[:dsid]
      end

      find_or_create_child_resource(opts[:path], opts[:prefix]).tap do |node|
        node.content = file
        node.mime_type = if opts[:mimeType]
          Deprecation.warn AttachedFiles, "The :mimeType option to add_file is deprecated and will be removed in active-fedora 10.0. Use :mime_type instead", caller
          opts[:mimeType]
        else
          opts[:mime_type]
        end
        node.original_name = opts[:original_name]
      end
    end

    def undeclared_files
      @undeclared_files ||= []
    end


    private
      def create_singleton_association(file_path)
        self.undeclared_files << file_path.to_sym
        association = Associations::BasicContainsAssociation.new(self, Reflection::AssociationReflection.new(:contains, file_path, {class_name: 'ActiveFedora::File'}, self.class))
        @association_cache[file_path.to_sym] = association

        self.singleton_class.send :define_method, accessor_name(file_path) do
           @association_cache[file_path.to_sym].reader
        end
        association
      end

      def find_or_create_child_resource(path, prefix)
        association = association(path.to_sym) if path
        association ||= begin
          file_path = FilePathBuilder.build(self, path, prefix)
          create_singleton_association(file_path)
        end
        association.reader
      end

      ## Given a file_path return a standard name
      def accessor_name(file_path)
        file_path.gsub('-', '_')
      end


    module ClassMethods
      extend Deprecation
      self.deprecation_horizon = 'active-fedora version 10.0'

      def ds_specs
        child_resource_reflections
      end
      deprecation_deprecate :ds_specs

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
        raise ArgumentError, "You must provide a :type property for the datastream '#{name}'" unless args[:type]
        args[:class_name] = args.delete(:type).to_s
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
        args[:class_name] = args.delete(:type).to_s
        contains(name, args)
      end
      deprecation_deprecate :has_file_datastream
    end
  end
end
