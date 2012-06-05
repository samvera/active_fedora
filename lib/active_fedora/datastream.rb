module ActiveFedora

  #This class represents a Fedora datastream
  class Datastream < Rubydora::Datastream
    
    attr_writer :digital_object
    attr_accessor :last_modified, :fields
    before_create :add_mime_type, :add_ds_location, :validate_content_present
  
    def initialize(digital_object, dsid, options={})
      ## When you use the versions feature of rubydora (0.5.x), you need to have a 3 argument constructor
      self.fields={}
      super
    end
    
    def size
      self.profile['dsSize']
    end

    def add_mime_type
      self.mimeType = 'text/xml' unless self.mimeType
    end

    def add_ds_location
      if self.controlGroup == 'E'
      end
    end

    def inspect
      "#<#{self.class}:#{self.hash} @pid=\"#{digital_object ? pid : nil}\" @dsid=\"#{dsid}\" @controlGroup=\"#{controlGroup}\" @dirty=\"#{dirty}\" @mimeType=\"#{mimeType}\" >"
    end

    #compatibility method for rails' url generators. This method will 
    #urlescape escape dots, which are apparently
    #invalid characters in a dsid.
    def to_param
      dsid.gsub(/\./, '%2e')
    end
    
    # Test whether this datastream been modified since it was last saved
    def dirty?
      changed?
    end
    
    def dirty
      changed?
    end
    
    def dirty=(value)
      if value
        content_will_change! # an innocent hack to pretend something has changed
      else
        changed_attributes.clear
      end
    end

    def new_object?
      new?
    end

    def validate_content_present
      case controlGroup
      when 'X','M'
        @content.present?
      when 'E','R'
        dsLocation.present?
      else
        raise "Invalid control group: #{controlGroup.inspect}"
      end      
    end
    
    def save
      run_callbacks :save do
        return create if new?
        repository.modify_datastream to_api_params.merge({ :pid => pid, :dsid => dsid })
        reset_profile_attributes
        #Datastream.new(digital_object, dsid)
        self
      end
    end

    def create
      run_callbacks :create do
        repository.add_datastream to_api_params.merge({ :pid => pid, :dsid => dsid })
        reset_profile_attributes
        self
      end
    end


    # serializes any changed data into the content field
    def serialize!
    end
    # Populate a Datastream object based on the "datastream" node from a FOXML file
    # @param [ActiveFedora::Datastream] tmpl the Datastream object that you are building
    # @param [Nokogiri::XML::Node] node the "foxml:datastream" node from a FOXML file
    def self.from_xml(tmpl, node)
      tmpl.controlGroup= node['CONTROL_GROUP']
      tmpl
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
        profile[key] = value.to_s
      end
    end
  end
  
  class DatastreamConcurrencyException < Exception # :nodoc:
  end
end
