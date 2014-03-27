module ActiveFedora

  #This class represents a Fedora datastream
  class Datastream
    include FedoraLens
    attribute :mime_type, [RDF::URI.new("http://fedora.info/definitions/v4/repository#mimeType"), Lenses.single, Lenses.literal_to_string]

    include ActiveModel::Dirty
    define_attribute_methods :content

    extend ActiveModel::Callbacks
    define_model_callbacks :save, :create, :destroy
    define_model_callbacks :initialize, :only => :after    

    attr_reader :digital_object, :dsid
    attr_accessor :last_modified

    # @param digital_object [DigitalObject] the digital object that this object belongs to
    # @param dsid [String] the datastream id, if this is nil, a datastream id will be generated.
    # @param options [Hash]
    # @option options [String,IO] :content the content for the datastream
    # @option options [String] :dsLabel label for the datastream
    # @option options [String] :dsLocation location for an external or redirect datastream
    # @option options [String] :mimeType the mime-type of the content
    # @option options [String] :prefix the prefix for the auto-generated DSID (not to be confused with the solr prefix)
    # @option options [Boolean] :versionable is the datastream versionable
    def initialize(digital_object, dsid=nil, options={})
      raise ArgumentError, "Digital object is nil" unless digital_object
      @digital_object = digital_object
      dsid = nil if dsid == ''
      dsid ||= generate_dsid(digital_object, options.delete(:prefix) || "DS")
      @dsid = dsid
      if digital_object.new_record?
        init_core("#{digital_object.uri}/#{dsid}")
      else
        init_core(nil)
      end
    end

    def content= string_or_io
      content_will_change!
      @content = string_or_io
    end

    def content
      return @content if new_record?
      @content ||= datastream_content
      @content
    end

    def datastream_content
      return if new_record?
      @ds_content ||= retrieve_content
    end

    def mime_type
      attributes["mimeType"] || default_mime_type
    end

    def default_mime_type
      'text/plain'
    end

    def content_changed?
      !!@content
    end

    def uri
      new_record? ? "#{digital_object.uri}/#{dsid}" : super
    end

    def save
      return unless content_changed?
      raise "Can't generate uri because the parent object isn't saved" if digital_object.new_record?
      resp = orm.resource.client.post "#{uri}/fcr:content", content, 'Content-Type' => mime_type
      case resp.status
        when 201
          return true
        when 404
          raise ActiveFedora::ObjectNotFoundError, "Unable to add content at #{uri}/fcr:content"
        else
          raise "unexpected return value #{resp.status}"
      end
    end

    def retrieve_content
      orm.resource.client.get("#{uri}/fcr:content").body
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
    
    # TODO size premis:hasSize

    # alias_method :realLabel, :label

    # def label
    #   Array(realLabel).first
    # end
    # alias_method :dsLabel, :label

    def inspect
      "#<#{self.class} @pid=\"#{digital_object.id}\" @dsid=\"#{dsid}\" changed=\"#{changed?}\" @mimeType=\"#{mimeType}\" >"
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
    
    def solrize_profile # :nodoc:
      profile_hash = {}
      profile.each_pair do |property,value|
        if property =~ /Date/
          value = Time.parse(value) unless value.is_a?(Time)
          value = value.xmlschema
        end
        profile_hash[property] = value
      end
      profile_hash
    end
    
    def profile_from_hash(profile_hash)
      profile_hash.each_pair do |key,value|
        profile[key] = value
      end
    end
    
    def to_solr(solr_doc = Hash.new)
      solr_doc
    end

    protected

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
      raise RuntimeError, "to_solr requires the dsid to be set" unless dsid
      "#{dsid.underscore}__"
    end

  end
  
  class DatastreamConcurrencyException < Exception # :nodoc:
  end
end
