require 'fedora/base'
require 'fedora/repository'

class Fedora::Datastream < Fedora::BaseObject
  
  attr_accessor :mime_type
  
  def initialize(attrs = {})
    super
    if attrs
      if attrs[:mime_type] 
        self.mime_type = attrs[:mime_type]
      elsif attrs[:mimeType] 
        self.mime_type = attrs[:mimeType]
      end 
    end
    self.control_group='M' if @attributes[:mimeType]
  end
  
  def pid
    attributes[:pid]
  end

  def control_group
    @attributes[:controlGroup]
  end
  def control_group=(cg)
    @attributes[:controlGroup]=cg
  end
  
  def dsid
    if attributes.has_key?(:dsid) 
      attributes[:dsid]
    else
      attributes[:dsID]
    end
  end
  
  def label
    @attributes[:dsLabel]
  end
  
  def label=(new_label)
    @attributes[:dsLabel] = new_label
  end
  
  # See http://www.fedora.info/definitions/identifiers/
  def uri
    "fedora:info/#{pid}/datastreams/#{dsid}"
  end
  
  # @returns the url of the datastream in Fedora, without the repository userinfo
  def url
    return "#{Fedora::Repository.instance.base_url}/objects/#{pid}/datastreams/#{dsid}"
  end
end
