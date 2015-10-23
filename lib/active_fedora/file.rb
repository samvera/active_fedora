require 'deprecation'

module ActiveFedora
  # An LDP NonRDFSource. The base class for a bytestream stored in the repository.
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

    # @param parent_or_url_or_hash [ActiveFedora::Base, RDF::URI, String, Hash, NilClass] the parent resource or the URI of this resource
    # @param path [String] the path partial relative to the resource
    # @param options [Hash]
    # @yield [self] Yields self
    # @yieldparam [File] self the newly created file
    def initialize(parent_or_url_or_hash = nil, path = nil, _options = {}, &_block)
      case parent_or_url_or_hash
      when Hash
        @ldp_source = build_ldp_resource_via_uri
      when nil
        @ldp_source = build_ldp_resource_via_uri nil
      when String, ::RDF::URI
        id = ActiveFedora::Associations::IDComposite.new([parent_or_url_or_hash], translate_uri_to_id).first
        @ldp_source = build_ldp_resource id
      when ActiveFedora::Base
        Deprecation.warn File, "Initializing a file by passing a container is deprecated. Initialize with a uri instead. This capability will be removed in active-fedora 10.0"
        uri = if parent_or_url_or_hash.uri.is_a?(::RDF::URI) && parent_or_url_or_hash.uri.value.empty?
                nil
              else
                "#{parent_or_url_or_hash.uri}/#{path}"
              end
        @ldp_source = build_ldp_resource_via_uri(uri, nil)

      else
        raise "The first argument to #{self} must be a String or an ActiveFedora::Base. You provided a #{parent_or_url_or_hash.class}"
      end

      @attributes = {}.with_indifferent_access
      yield self if block_given?
    end

    # @return [true, false] true if the objects are equal or when the objects have uris
    #   and the uris are equal
    def ==(other)
      super ||
        other.instance_of?(self.class) &&
          uri.value.present? &&
          other.uri == uri
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

    def uri=(uri)
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

    def checksum
      ActiveFedora::Checksum.new(self)
    end

    def content_changed?
      return true if new_record? && !local_or_remote_content(false).blank?
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
      @frozen.present?
    end

    # serializes any changed data into the content field
    def serialize!
    end

    def to_solr(solr_doc = {}, _opts = {})
      solr_doc
    end

    def content=(string_or_io)
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
        [IO, Tempfile, StringIO].any? { |klass| obj.is_a? klass } || (defined?(Rack) && obj.is_a?(Rack::Test::UploadedFile))
      end

      def retrieve_content
        ldp_source.get.body
      end

      def ldp_headers
        headers = { 'Content-Type'.freeze => mime_type, 'Content-Length'.freeze => content.size.to_s }
        headers['Content-Disposition'.freeze] = "attachment; filename=\"#{URI.encode(@original_name)}\"" if @original_name
        headers
      end

      def create_record(_options = {})
        return false if content.nil?
        ldp_source.content = content
        ldp_source.create do |req|
          req.headers.merge!(ldp_headers)
        end
        refresh
      end

      def update_record(_options = {})
        return true unless content_changed?
        ldp_source.content = content
        ldp_source.update do |req|
          req.headers.merge!(ldp_headers)
        end
        refresh
      end

      def build_ldp_resource(id)
        build_ldp_resource_via_uri self.class.id_to_uri(id)
      end

      def build_ldp_resource_via_uri(uri = nil, content = '')
        Ldp::Resource::BinarySource.new(ldp_connection, uri, content, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
      end

      def uploaded_file?(payload)
        defined?(ActionDispatch::Http::UploadedFile) && payload.instance_of?(ActionDispatch::Http::UploadedFile)
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
