module ActiveFedora

  #This class represents a Fedora datastream
  class Datastream < Rubydora::Datastream
    extend Deprecation
    attr_writer :digital_object
    attr_accessor :last_modified

    def initialize(digital_object=nil, dsid=nil, options={})
      ## When you use the versions feature of rubydora (0.5.x), you need to have a 3 argument constructor
      super
    end

    alias_method :realLabel, :label

    def label
      Array(realLabel).first
    end
    alias_method :dsLabel, :label

    def inspect
      "#<#{self.class} @pid=\"#{digital_object ? pid : nil}\" @dsid=\"#{dsid}\" @controlGroup=\"#{controlGroup}\" changed=\"#{changed?}\" @mimeType=\"#{mimeType}\" >"
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

    def save
      super
      self
    end

    def create
      super
      self
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
    # The string to prefix all solr fields with. Override this method if you want
    # a prefix other than the default
    def prefix
      raise RuntimeError, "to_solr requires the dsid to be set" unless dsid
      Deprecation.warn ActiveFedora::Datastream, "In active-fedora 8 the solr fields created by #{self.class} will be prefixed with \"#{dsid.underscore}__\".  If you want to maintain the existing behavior, you must override #{self.class}.#prefix to return an empty string"
      # In ActiveFedora 8 return this:
      #"#{dsid.underscore}__"
      ""
    end

  end
  
  class DatastreamConcurrencyException < Exception # :nodoc:
  end
end
