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

    #compatibility method for rails' url generators. This method will 
    #urlescape escape dots, which are apparently
    #invalid characters in a dsid.
    def to_param
      dsid.gsub(/\./, '%2e')
    end
    
    #has this datastream been modified since it was last saved?
    def dirty?
      @dirty
    end
  
    #saves this datastream into fedora.
    def save
      before_save
      result = Fedora::Repository.instance.save(self)
      after_save
      result
    end
    
    def before_save # :nodoc:
      #check_concurrency
    end
    def self.from_xml(tmpl, el)
      el.elements.each("foxml:xmlContent/fields") do |f|
        tmpl.send("#{f.name}_append", f.text)
      end
      tmpl.instance_variable_set(:@dirty, false)
      tmpl.control_group= el.attributes['CONTROL_GROUP']
      tmpl
    end
    
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
        
        puts datastream_xml.length
        if datastream_xml.length > 3
          datastream_xml.elements.each do |el|
            puts el.inspect
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
