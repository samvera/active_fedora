module ActiveFedora
  # An LDP NonRDFSource. The base class for a bytestream stored in the repository.
  class File
    extend ActiveModel::Callbacks
    extend ActiveSupport::Autoload
    extend ActiveTriples::Properties
    extend Querying

    autoload :Streaming
    autoload :Attributes

    include Common
    include ActiveFedora::File::Attributes
    include ActiveFedora::File::Streaming
    include ActiveFedora::FilePersistence
    include ActiveFedora::Versionable
    include ActiveModel::Dirty
    include ActiveFedora::Callbacks
    include AttributeMethods # allows 'content' to be tracked
    include Identifiable
    include Inheritance
    include Scoping

    generate_method 'content'

    define_model_callbacks :update, :save, :create, :destroy
    define_model_callbacks :initialize, only: :after

    # @param [Hash, RDF::URI, String, NilClass] identifier the id (path) or URI of this resource. The hash gets passed when calling Reflection#build_association, but currently we don't do anything with it.
    # @yield [self] Yields self
    # @yieldparam [File] self the newly created file
    def initialize(identifier = nil, &_block)
      identifier = identifier.delete(:id) if identifier.is_a? Hash
      identifier = identifier.uri if identifier.respond_to? :uri
      run_callbacks(:initialize) do
        case identifier
        when nil, ::RDF::URI
          @ldp_source = build_ldp_resource_via_uri identifier
        when String
          id = ActiveFedora::Associations::IDComposite.new([identifier], translate_uri_to_id).first
          @ldp_source = build_ldp_resource id
        else
          raise "The first argument to #{self} must be a Hash, String or RDF::URI. You provided a #{identifier.class}"
        end

        @local_attributes = {}.with_indifferent_access
        @readonly = false
        yield self if block_given?
      end
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
      @ds_content = nil
      clear_attribute_changes(changes.keys)
    end

    def check_fixity
      FixityService.new(@ldp_source.subject).check
    end

    def datastream_will_change!
      attribute_will_change! :ldp_source
    end

    def attribute_will_change!(attr)
      return super unless attr == 'content'
      attributes_changed_by_setter[:content] = true
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

    def metadata_changed?
      return false if new_record? || links['describedby'].blank?
      metadata.changed?
    end

    def changed?
      super || content_changed? || metadata_changed?
    end

    def inspect
      "#<#{self.class} uri=\"#{uri}\" >"
    end

    # @abstract Override this in your concrete datastream class.
    # @return [boolean] does this datastream contain metadata (not file data)
    def metadata?
      false
    end

    # serializes any changed data into the content field
    def serialize!; end

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

    def self.relation
      FileRelation.new(self)
    end
    private_class_method :relation

    private

      def create_or_update(*options)
        super.tap do
          metadata.save if metadata.changed?
        end
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

      def build_ldp_resource(id)
        build_ldp_resource_via_uri self.class.id_to_uri(id)
      end

      def build_ldp_resource_via_uri(uri = nil, content = '')
        Ldp::Resource::BinarySource.new(ldp_connection, uri, content, base_path_for_resource)
      end

      def uploaded_file?(payload)
        defined?(ActionDispatch::Http::UploadedFile) && payload.instance_of?(ActionDispatch::Http::UploadedFile)
      end

      def local_or_remote_content(ensure_fetch = true)
        return @content if new_record?

        @content ||= ensure_fetch ? remote_content : @ds_content
        @content.rewind if behaves_like_io?(@content)
        @content
      end
  end
end
