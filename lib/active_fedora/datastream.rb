require 'fedora/datastream'
module ActiveFedora

  #This class represents a Fedora datastream
  class Datastream < Fedora::Datastream
    
    attr_accessor :dirty, :last_modified, :fields
  
    def initialize(attrs = {})
      @fields={}
      @dirty = false
      super
    end
    
    #Return the xml content representing this Datastream from Fedora
    def content
      result = Fedora::Repository.instance.fetch_custom(self.attributes[:pid], "datastreams/#{self.dsid}/content")
      return result
    end
  
    #set this Datastream's content
    def content=(content)
      self.blob = content
      self.dirty = true
    end

    def self.delete(parent_pid, dsid)
      Fedora::Repository.instance.delete("%s/datastreams/%s"%[parent_pid, dsid])
    end

    def delete
      self.class.delete(self.pid, self.dsid)
    end
    
    #get this datastreams identifier
    def pid
      self.attributes[:pid]
    end
  
    #set this datastreams parent identifier
    def pid=(pid)
      self.attributes[:pid] = pid
    end
    
    #set this datastreams identifier (note: sets both dsID and dsid)
    def dsid=(dsid)
      self.attributes[:dsID] = dsid
      self.attributes[:dsid] = dsid
    end

    def size
      if !self.attributes.fetch(:dsSize,nil)
        if self.new_object?
          self.attributes[:dsSize]=nil
        else
          attrs = XmlSimple.xml_in(Fedora::Repository.instance.fetch_custom(self.pid,"datastreams/#{self.dsid}"))
          self.attributes[:dsSize]=attrs["dsSize"].first
        end
      end
      self.attributes[:dsSize]
    end

    #compatibility method for rails' url generators. This method will 
    #urlescape escape dots, which are apparently
    #invalid characters in a dsid.
    def to_param
      dsid.gsub(/\./, '%2e')
    end
    
    # Test whether this datastream been modified since it was last saved?
    def dirty?
      @dirty
    end
  
    # Save the datastream into fedora.
    # Also triggers {#before_save} and {#after_save} callbacks
    def save
      before_save
      result = Fedora::Repository.instance.save(self)
      after_save
      result
    end
    
    # Callback.  Does nothing by default.  Override this to insert behaviors before the save method.
    def before_save 
      #check_concurrency
    end
    
    # Populate a Datastream object based on the "datastream" node from a FOXML file
    # @param [ActiveFedora::Datastream] tmpl the Datastream object that you are building
    # @param [Nokogiri::XML::Node] node the "foxml:datastream" node from a FOXML file
    def self.from_xml(tmpl, node)
      tmpl.instance_variable_set(:@dirty, false)
      tmpl.control_group= node['CONTROL_GROUP']
      tmpl
    end
    
    # Callback.  Override this to insert behaviors after the save method.  By default, sets self.dirty = false
    def after_save
      self.dirty = false
    end
    
    # returns a datetime in the standard W3C DateTime Format.  
    # ie 2008-10-17T00:17:18.194Z
    def last_modified_in_repository
      # A hack to get around the fact that you can't call getDatastreamHistory 
      # or API-M getDatasreams on Fedora 3.0 REST API  
      # grabs the CREATED attribute off of the last foxml:datastreamVersion 
      # within the appropriate datastream node in the objectXML
      if self.pid != nil
        object_xml = Fedora::FedoraObject.object_xml(self.pid).gsub("\n     ","")
        datastream_xml = REXML::Document.new(object_xml).root.elements["foxml:datastream[@ID='#{self.dsid}']"]
        
        if datastream_xml.length > 3
          datastream_xml.elements.each do |el|
            logger.debug el.inspect
          end
        end
        
        datastream_xml.elements[datastream_xml.length - 2].attributes["CREATED"]
      else
        return nil
      end
    end
    
    def check_concurrency # :nodoc:
      return true
    end
    
  end
  
  class DatastreamConcurrencyException < Exception # :nodoc:
  end
end
