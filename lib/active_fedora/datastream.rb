module ActiveFedora

  #This class represents a Fedora datastream
  class Datastream < Rubydora::Datastream
    
    attr_writer :digital_object
    attr_accessor :dirty, :last_modified, :fields
    before_create :add_mime_type
  
    def initialize(digital_object, dsid)
      @fields={}
      @dirty = false
      super
    end
    
    def size
      self.profile['dsSize']
    end

    def add_mime_type
      self.mimeType = 'text/xml' unless self.mimeType
    end

    #compatibility method for rails' url generators. This method will 
    #urlescape escape dots, which are apparently
    #invalid characters in a dsid.
    def to_param
      dsid.gsub(/\./, '%2e')
    end
    
    # Test whether this datastream been modified since it was last saved
    def dirty?
      @dirty || changed?
    end

    def new_object?
      new?
    end

    def save
      #raise "No content #{dsid}" if @content.nil?
      return if @content.nil?
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
      tmpl.instance_variable_set(:@dirty, false)
      tmpl.control_group= node['CONTROL_GROUP']
      tmpl
    end
    
    # # Callback.  Override this to insert behaviors after the save method.  By default, sets self.dirty = false
    # def after_save
    #   self.dirty = false
    # end
    
    # returns a datetime in the standard W3C DateTime Format.  
    # ie 2008-10-17T00:17:18.194Z
    # def last_modified_in_repository
    #   # A hack to get around the fact that you can't call getDatastreamHistory 
    #   # or API-M getDatasreams on Fedora 3.0 REST API  
    #   # grabs the CREATED attribute off of the last foxml:datastreamVersion 
    #   # within the appropriate datastream node in the objectXML
    #   if self.pid != nil
    #     object_xml = Fedora::FedoraObject.object_xml(self.pid).gsub("\n     ","")
    #     datastream_xml = REXML::Document.new(object_xml).root.elements["foxml:datastream[@ID='#{self.dsid}']"]
    #     
    #     if datastream_xml.length > 3
    #       datastream_xml.elements.each do |el|
    #         logger.debug el.inspect
    #       end
    #     end
    #     
    #     datastream_xml.elements[datastream_xml.length - 2].attributes["CREATED"]
    #   else
    #     return nil
    #   end
    # end
    
    def check_concurrency # :nodoc:
      return true
    end
    
  end
  
  class DatastreamConcurrencyException < Exception # :nodoc:
  end
end
