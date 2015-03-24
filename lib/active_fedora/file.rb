module ActiveFedora

  #This class represents a Fedora datastream
  class File
    include AttributeMethods # allows 'content' to be tracked
    include ActiveModel::Dirty
    extend Deprecation
    extend ActiveTriples::Properties
    generate_method 'content'

    extend ActiveModel::Callbacks
    define_model_callbacks :save, :create, :destroy
    define_model_callbacks :initialize, only: :after

    # @param parent_or_url [ActiveFedora::Base, String, Hash, NilClass] the parent resource or the URI of this resource
    # @param path_name [String] the path partial relative to the resource
    # @param options [Hash]
    def initialize(parent_or_url_or_hash = nil, path=nil, options={})
      case parent_or_url_or_hash
      when Hash
        content = ''
        @ldp_source = Ldp::Resource::BinarySource.new(ldp_connection, nil, content, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
      when nil, String
      #TODO this is similar to Core#build_ldp_resource
        content = ''
        @ldp_source = Ldp::Resource::BinarySource.new(ldp_connection, parent_or_url_or_hash, content, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
      when ActiveFedora::Base
        Deprecation.warn File, "Initializing a file by passing a container is deprecated. Initialize with a uri instead. This capability will be removed in active-fedora 10.0"
        uri = if parent_or_url_or_hash.uri.kind_of?(::RDF::URI) && parent_or_url_or_hash.uri.value.empty?
          nil
        else
          "#{parent_or_url_or_hash.uri}/#{path}"
        end
        @ldp_source = Ldp::Resource::BinarySource.new(ldp_connection, uri, nil, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)

      else
        raise "The first argument to #{self} must be a String or an ActiveFedora::Base. You provided a #{parent_or_url.class}"
      end

      @attributes = {}.with_indifferent_access
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

    # TODO this is like FedoraAttributes#uri
    def uri
      ldp_source.subject
    end

    # If this file have a parent with ldp#contains, we know it is not new.
    # By tracking exists we prevent an unnecessary HEAD request.
    def new_record?
      !@exists && ldp_source.new?
    end

    def uri= uri
      @ldp_source = Ldp::Resource::BinarySource.new(ldp_connection, uri, '', ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
    end

    # If we know the record to exist (parent has LDP:contains), we can avoid unnecessary HEAD requests
    def exists!
      @exists = true
    end

    # When restoring from previous versions, we need to reload certain attributes from Fedora
    def reload
      return if new_record?
      reset
    end

    def reset
      @ldp_source = Ldp::Resource::BinarySource.new(ldp_connection, uri)
      @original_name = nil
      @mime_type = nil
      @content = nil
      @metadata = nil
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

    attr_writer :mime_type
    def mime_type
      @mime_type ||= fetch_mime_type unless new_record?
      @mime_type || default_mime_type
    end

    def metadata
      @metadata ||= ActiveFedora::WithMetadata::MetadataNode.new(self)
    end

    def original_name
      @original_name ||= fetch_original_name_from_headers
    end

    def digest
      response = metadata.ldp_source.graph.query(predicate: ActiveFedora::RDF::Fcrepo4.digest)
      response.map(&:object)
    end

    def persisted_size
      ldp_source.head.headers['Content-Length'].to_i unless new_record?
    end

    def dirty_size
      content.size if changed? && content.respond_to?(:size)
    end

    def size
      dirty_size || persisted_size
    end

    def has_content?
      size && size > 0
    end

    def empty?
      !has_content?
    end

    def content_changed?
      return true if new_record? and !local_or_remote_content(false).blank?
      local_or_remote_content(false) != @ds_content
    end

    def changed?
      super || content_changed?
    end

    def original_name= name
      @original_name = name
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

    protected

    def default_mime_type
      'text/plain'
    end

    # The string to prefix all solr fields with. Override this method if you want
    # a prefix other than the default
    def prefix(path)
      path ? "#{path.underscore}__" : ''
    end

    def fetch_original_name_from_headers
      return if new_record?
      m = ldp_source.head.headers['Content-Disposition'].match(/filename="(?<filename>[^"]*)";/)
      URI.decode(m[:filename])
    end

    def fetch_mime_type
      ldp_source.head.headers['Content-Type']
    end

    private

    def links
      @links ||= Ldp::Response.links(ldp_source.head)
    end


    # Rack::Test::UploadedFile is often set via content=, however it's not an IO, though it wraps an io object.
    def behaves_like_io?(obj)
      [IO, Tempfile, StringIO].any? { |klass| obj.kind_of? klass } || (defined?(Rack) && obj.is_a?(Rack::Test::UploadedFile))
    end

    # Persistence is an included module, so that we can include other modules which override these methods
    module Persistence
      def content= string_or_io
        content_will_change! unless @content == string_or_io
        @content = string_or_io
      end

      def content
        local_or_remote_content(true)
      end

      def save(*)
        return unless content_changed?
        headers = { 'Content-Type'.freeze => mime_type, 'Content-Length'.freeze => content.size.to_s }
        headers['Content-Disposition'.freeze] = "attachment; filename=\"#{URI.encode(@original_name)}\"" if @original_name

        ldp_source.content = content
        if new_record?
          ldp_source.create do |req|
            req.headers.merge!(headers)
          end
        else
          ldp_source.update do |req|
            req.headers.merge!(headers)
          end
        end
        reset
        changed_attributes.clear
      end

      def retrieve_content
        ldp_source.get.body
      end

      private

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

    module Streaming
      # @param range [String] the Range HTTP header
      # @returns [Stream] an object that responds to each
      def stream(range = nil)
        uri = URI.parse(self.uri)
        FileBody.new(uri, headers(range, authorization_key))
      end

      # @returns current authorization token from Ldp::Client
      def authorization_key
        self.ldp_source.client.http.headers.fetch("Authorization", nil)
      end

      # @param range [String] from #stream
      # @param key [String] from #authorization_key
      # @returns [Hash]
      def headers(range, key, result = Hash.new)
        result["Range"] = range if range
        result["Authorization"] = key if key
        result
      end

      class FileBody
        attr_reader :uri, :headers
        def initialize(uri, headers)
          @uri = uri
          @headers = headers
        end

        def each
          Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new uri, headers
            http.request request do |response|

              raise "Couldn't get data from Fedora (#{uri}). Response: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
              response.read_body do |chunk|
                yield chunk
              end
            end
          end
        end
      end
    end

    include ActiveFedora::File::Persistence
    include ActiveFedora::File::Streaming
    include ActiveFedora::Versionable
  end

end
