require 'deprecation'

module ActiveFedora
  class File
    extend ActiveModel::Callbacks
    extend ActiveSupport::Autoload
    extend ActiveTriples::Properties
    extend Deprecation
    extend Querying

    autoload :Streaming
    autoload :Attributes

    include ActiveFedora::File::Attributes
    include ActiveFedora::File::Streaming
    include ActiveFedora::Persistence
    include ActiveFedora::Versionable
    include ActiveModel::Dirty
    include AttributeMethods # allows 'content' to be tracked
    include Identifiable
    include Scoping

    generate_method 'content'

    define_model_callbacks :save, :create, :destroy
    define_model_callbacks :initialize, only: :after

    # @param parent_or_url_or_hash [ActiveFedora::Base, String, Hash, NilClass] the parent resource or the URI of this resource
    # @param path [String] the path partial relative to the resource
    # @param options [Hash]
    def initialize(parent_or_url_or_hash = nil, path=nil, options={})
      case parent_or_url_or_hash
      when Hash
        @ldp_source = build_ldp_resource_via_uri
      when nil, String
        @ldp_source = build_ldp_resource_via_uri parent_or_url_or_hash
      when ActiveFedora::Base
        Deprecation.warn File, "Initializing a file by passing a container is deprecated. Initialize with a uri instead. This capability will be removed in active-fedora 10.0"
        uri = if parent_or_url_or_hash.uri.kind_of?(::RDF::URI) && parent_or_url_or_hash.uri.value.empty?
          nil
        else
          "#{parent_or_url_or_hash.uri}/#{path}"
        end
        @ldp_source = build_ldp_resource_via_uri(uri, nil)

      else
        raise "The first argument to #{self} must be a String or an ActiveFedora::Base. You provided a #{parent_or_url.class}"
      end

      @attributes = {}.with_indifferent_access
    end

    def ==(comparison_object)
      return true if comparison_object.equal?(self)
      comparison_object.instance_of?(self.class) && comparison_object.uri == uri && !comparison_object.new_record?
    end

    def ldp_source
      @ldp_source || raise("NO source")
    end

    def described_by
      raise "#{self} isn't persisted yet" if new_record?
      links['describedby'].first
    end

    def ldp_connection
      ActiveFedora.fedora.connection
    end

    # If this file has a parent with ldp#contains, we know it is not new.
    # By tracking exists we prevent an unnecessary HEAD request.
    def new_record?
      !@exists && ldp_source.new?
    end

    def uri= uri
      @ldp_source = build_ldp_resource_via_uri(uri)
    end

    # If we know the record to exist (parent has LDP:contains), we can avoid unnecessary HEAD requests
    def exists!
      @exists = true
    end

    # When restoring from previous versions, we need to reload certain attributes from Fedora
    def reload
      return if new_record?
      refresh
    end

    def refresh
      @ldp_source = build_ldp_resource_via_uri(uri)
      @original_name = nil
      @mime_type = nil
      @content = nil
      @metadata = nil
      changed_attributes.clear
    end

    def check_fixity
      FixityService.new(@ldp_source.subject).check
    end

    def datastream_will_change!
      attribute_will_change! :profile
    end

    def attribute_will_change!(attr)
      if attr == 'content'
        changed_attributes['content'] = true
      else
        super
      end
    end

    def remote_content
      return if new_record?
      @ds_content ||= retrieve_content
    end

    def metadata
      @metadata ||= ActiveFedora::WithMetadata::MetadataNode.new(self)
    end

    def content_changed?
      return true if new_record? and !local_or_remote_content(false).blank?
      local_or_remote_content(false) != @ds_content
    end

    def changed?
      super || content_changed?
    end

    def inspect
      "#<#{self.class} uri=\"#{uri}\" >"
    end

    # @abstract Override this in your concrete datastream class.
    # @return [boolean] does this datastream contain metadata (not file data)
    def metadata?
      false
    end

    # Freeze datastreams such that they can be loaded from Fedora, but can't be changed
    def freeze
      @frozen = true
    end

    def frozen?
      !!@frozen
    end

    # serializes any changed data into the content field
    def serialize!
    end

    def to_solr(solr_doc={}, opts={})
      solr_doc
    end

    def content= string_or_io
      content_will_change! unless @content == string_or_io
      @content = string_or_io
    end

    def content
      local_or_remote_content(true)
    end

    def readonly?
      false
    end

    protected

      # The string to prefix all solr fields with. Override this method if you want
      # a prefix other than the default
      def prefix(path)
        path ? "#{path.underscore}__" : ''
      end

    private

      def self.relation
        FileRelation.new(self)
      end

      # Rack::Test::UploadedFile is often set via content=, however it's not an IO, though it wraps an io object.
      def behaves_like_io?(obj)
        [IO, Tempfile, StringIO].any? { |klass| obj.kind_of? klass } || (defined?(Rack) && obj.is_a?(Rack::Test::UploadedFile))
      end

      def retrieve_content
        ldp_source.get.body
      end

      def ldp_headers
        headers = { 'Content-Type'.freeze => mime_type, 'Content-Length'.freeze => content.size.to_s }
        headers['Content-Disposition'.freeze] = "attachment; filename=\"#{URI.encode(@original_name)}\"" if @original_name
        headers
      end

      def create_record(options = {})
        return false if content.nil?
        ldp_source.content = content
        ldp_source.create do |req|
          req.headers.merge!(ldp_headers)
        end
        refresh
      end

      def update_record(options = {})
        return true unless content_changed?
        ldp_source.content = content
        ldp_source.update do |req|
          req.headers.merge!(ldp_headers)
        end
        refresh
      end

      def build_ldp_resource_via_uri(uri=nil, content='')
        Ldp::Resource::BinarySource.new(ldp_connection, uri, content, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
      end

      def uploaded_file?(payload)
        defined?(ActionDispatch::Http::UploadedFile) and payload.instance_of?(ActionDispatch::Http::UploadedFile)
      end

      def local_or_remote_content(ensure_fetch = true)
        return @content if new_record?

        @content ||= ensure_fetch ? remote_content : @ds_content

        if behaves_like_io?(@content)
          begin
            @content.rewind
            @content.read
          ensure
            @content.rewind
          end
        else
          @content
        end
        @content
      end

  end

end
