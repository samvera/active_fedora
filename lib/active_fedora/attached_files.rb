module ActiveFedora
  module AttachedFiles
    extend ActiveSupport::Concern

    def serialize_attached_files
      declared_attached_files.each_value(&:serialize!)
    end

    # Returns only the attached_files that are declared with 'contains'
    def declared_attached_files
      attached_files.reflections.keys.each_with_object({}) do |k, h|
        h[k] = attached_files[k]
      end
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

    def clear_attached_files
      @attached_files = nil
    end

    def contains_assertions
      resource.query(subject: resource, predicate: ::RDF::Vocab::LDP.contains).objects.map(&:to_s)
    end

    # Load any undeclared relationships or has_subresource relationships.  These are non-idiomatic LDP
    # because we are going to find the subresource by knowing it's subpath ahead of time.
    # Does nothing if this object is using idiomatic basic containment, by declaring `is_a_container`
    def load_attached_files
      return if reflections[:contains] && reflections[:contains].macro == :is_a_container
      contains_assertions.each do |file_uri|
        path = file_uri.to_s.sub(uri + '/', '')
        next if association(path.to_sym)
        create_singleton_association(path)
      end
    end

    # Add an ActiveFedora::File to the object.
    # @param [ActiveFedora::File] file
    # @param [String] file_path
    # @param [Hash] _opts
    # @return [String] path of the added datastream
    def attach_file(file, file_path, _opts = {})
      create_singleton_association(file_path)
      attached_files[file_path] = file
      file_path
    end

    # @return [Array] all attached files that return true for `metadata?` and are not Rels-ext
    def metadata_streams
      attached_files.select { |_k, ds| ds.metadata? }.values
    end

    #
    # File Management
    #

    # Attach the given stream/string to object
    #
    # @param [IO, String] file the file to add
    # @param [Hash] args options: :dsid, :prefix, :mime_type
    # @option opts [String] :path The file path
    # @option opts [String] :prefix The path prefix (for auto-generated path)
    # @option opts [String] :mime_type The Mime-Type of the file
    # @option opts [String] :original_name The original name of the file (used for Content-Disposition)
    def add_file(file, opts)
      find_or_create_child_resource(opts[:path], opts[:prefix]).tap do |node|
        node.content = file
        node.mime_type = opts[:mime_type]
        node.original_name = opts[:original_name]
        node.external_uri = opts[:external_uri]
        node.external_handling = opts[:external_handling]
      end
    end

    def undeclared_files
      @undeclared_files ||= []
    end

    private

      def create_singleton_association(file_path)
        undeclared_files << file_path.to_sym

        association = Associations::HasSubresourceAssociation.new(self, Reflection::HasSubresourceReflection.new(file_path, nil, { class_name: 'ActiveFedora::File' }, self.class))
        @association_cache[file_path.to_sym] = association

        singleton_class.send :define_method, accessor_name(file_path) do
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
        file_path.tr('-', '_')
      end
  end
end
