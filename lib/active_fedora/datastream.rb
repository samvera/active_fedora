module ActiveFedora

  #This class represents a Fedora datastream
  class Datastream
    include AttributeMethods
    include ActiveModel::Dirty
    extend ActiveTriples::Properties
    generate_method 'content'

    extend ActiveModel::Callbacks
    define_model_callbacks :save, :create, :destroy
    define_model_callbacks :initialize, only: :after

    attr_reader :digital_object, :dsid, :uri
    attr_accessor :last_modified

    # @param digital_object [DigitalObject] the digital object that this object belongs to
    # @param dsid [String] the datastream id, if this is nil, a datastream id will be generated.
    # @param options [Hash]
    # @option options [String,IO] :content the content for the datastream
    # @option options [String] :prefix the prefix for the auto-generated DSID (not to be confused with the solr prefix)
    def initialize(digital_object, dsid=nil, options={})
      raise ArgumentError, "Digital object is nil" unless digital_object
      @digital_object = digital_object
      initialize_dsid(dsid, options.delete(:prefix))

      #TODO if digital_object.uri is empty, then this resource is not valid:
      @uri = if digital_object.uri.kind_of?(RDF::URI) && digital_object.uri.value.empty?
        nil
      else
        "#{digital_object.uri}/#{@dsid}"
      end

      @attributes = {}.with_indifferent_access
      unless digital_object.new_record?
        @new_record = false
      end
    end

    def resource

    end

    def ldp_source
      @ldp_source ||= Ldp::Resource::BinarySource.new(ldp_connection, uri)
    end

    def ldp_connection
      ActiveFedora.fedora.connection
    end

    def metadata_resource
      #@orm ||= Rdf::ObjectResource.new(uri + '/fcr:metadata')
      @metadata_resource ||= Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri + '/fcr:metadata')
      puts "the Metadata resource is #{@metadata_resource.subject}."
      @metadata_resource
    end

    def new_record?
      uri.nil? || ldp_source.new?
    end


    def digital_object=(digital_object)
      raise ArgumentError, "must be a new record to assign a parent object" unless new_record?
      @uri = "#{digital_object.uri}/#{@dsid}"
      # resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
      # init_core(resource)
    end

    # When restoring from previous versions, we need to reload certain attributes from Fedora
    def reload
      return if new_record?
      @ldp_source = nil
      @original_name = nil
      @mime_type = nil
    end

    def initialize_dsid(dsid, prefix)
      prefix  ||= 'DS'
      dsid = nil if dsid == ''
      dsid ||= generate_dsid(digital_object, prefix)
      @dsid = dsid
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

    def datastream_content
      return if new_record?
      @ds_content ||= retrieve_content
    end

    attr_writer :mime_type
    def mime_type
      @mime_type ||= fetch_mime_type unless new_record?
      @mime_type || default_mime_type
    end

    def original_name
      @original_name ||= fetch_original_name_from_headers
    end

    def size
      ldp_source.head.headers['Content-Length'].to_i
    end

    def content_changed?
      return true if new_record? and !local_or_remote_content(false).blank?
      local_or_remote_content(false) != @ds_content
    end

    def changed?
      super || content_changed?
    end


    class << self
      def default_attributes
        {}
      end
    end

    def default_attributes
      @default_attributes ||= self.class.default_attributes
    end

    def default_attributes= attributes
      @default_attributes = default_attributes.merge attributes
    end

    def original_name= name
      @original_name = name
    end

    def inspect
      "#<#{self.class} uri=\"#{uri}\" changed=\"#{changed?}\" >"
    end

    #compatibility method for rails' url generators. This method will
    #urlescape escape dots, which are apparently
    #invalid characters in a dsid.
    def to_param
      dsid.gsub(/\./, '%2e')
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

    # return a valid dsid that is not currently in use.  Uses a prefix (default "DS") and an auto-incrementing integer
    # Example: if there are already datastreams with IDs DS1 and DS2, this method will return DS3.  If you specify FOO as the prefix, it will return FOO1.
    def generate_dsid(digital_object, prefix)
      return unless digital_object
      matches = digital_object.datastreams.keys.map {|d| data = /^#{prefix}(\d+)$/.match(d); data && data[1].to_i}.compact
      val = matches.empty? ? 1 : matches.max + 1
      format_dsid(prefix, val)
    end

    ### Provided so that an application can override how generated pids are formatted (e.g DS01 instead of DS1)
    def format_dsid(prefix, suffix)
      sprintf("%s%i", prefix,suffix)
    end

    # The string to prefix all solr fields with. Override this method if you want
    # a prefix other than the default
    def prefix
      "#{dsid.underscore}__"
    end

    def fetch_original_name_from_headers
      # TODO the HEAD didn't have Content-Disposition. Could this be a Fedora bug?
      m = ldp_source.get.headers['Content-Disposition'].match(/filename="(?<filename>[^"]*)";/)
      m[:filename]
    end

    def fetch_mime_type
      ldp_source.head.headers['Content-Type']
    end

    def query_metadata_node(predicate)
      query = metadata_resource.query([RDF::URI.new(uri), predicate, nil])
      stmt = query.first
      stmt.object.object if stmt
    end

    def reset_attributes
      @content = nil
    end

    private

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
        raise "Can't generate uri because the parent object isn't saved" if digital_object.new_record?
        payload = behaves_like_io?(content) ? content.read : content
        headers = { 'Content-Type' => mime_type }
        headers['Content-Disposition'] = "attachment; filename=\"#{@original_name}\"" if @original_name
        resp = ActiveFedora.fedora.connection.put @uri, payload, headers
        reset_attributes
        case resp.status
          when 201, 204
            changed_attributes.clear
          when 404
            raise ActiveFedora::ObjectNotFoundError, "Unable to add content at #{@container_resource.content_path}"
          else
            raise "unexpected return value #{resp.status}\n\t#{resp.body[0,200]}"
        end
      end

      def retrieve_content
        return '' if uri.nil?
        begin
          resp = ActiveFedora.fedora.connection.get(uri)
        rescue Ldp::NotFound
          return nil
        end
        case resp.status
          when 200, 201
            resp.body
          when 404
            # TODO
            # this happens because rdf_datastream calls datastream_content.
            # which happens because it needs a PID even though it isn't saved.
            # which happens because we don't know if something exists if you give it a pid
            #raise ActiveFedora::ObjectNotFoundError, "Unable to find content at #{uri}"
            ''
          else
            raise "unexpected return value #{resp.status} for when getting datastream content at #{uri}"
        end
      end

      # @param range [String] the Range HTTP header
      # @yield [chunk] a block that receives chunked content
      def stream(range = nil, &block)
        uri = URI.parse(self.uri)

        headers = {}
        headers['Range'] = range if range
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new uri, headers
          http.request request do |response|
            raise "Couldn't get data from Fedora (#{uri}). Response: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
            response.read_body do |chunk|
              block.call(chunk)
            end
          end
        end
      end

      private

      def local_or_remote_content(ensure_fetch = true)
        return @content if new_record?

        @content ||= ensure_fetch ? datastream_content : @ds_content

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

    include ActiveFedora::Datastream::Persistence
    include ActiveFedora::Versionable
  end

end
