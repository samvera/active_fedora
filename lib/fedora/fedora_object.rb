require 'xmlsimple'
require 'rexml/document'
require 'fedora/base'

class Fedora::FedoraObject < Fedora::BaseObject
  attr_accessor :target_repository

  # = Parameters
  # attrs<Hash>:: fedora object attributes (see below)
  #
  # == Attributes (attrs)
  # namespace<Symbol>::
  # pid<Symbol>::
  # state<Symbol>::
  # label<Symbol>::
  # contentModel<Symbol>::
  # objectXMLFormat<Symbol>::
  # ownerID<Symbol>::
  #-
  def initialize(attrs = nil)
    super
    # TODO: check for required attributes
  end

  ####
  #  Attribute Accessors
  ####
  
  
  def load_attributes_from_fedora
    #self.attributes.merge!(profile)
    attributes.merge!(profile)
  end
  
  # Reads all object properties from the object's FOXML into a hash.  Provides slightly more info than .profile, including the object state.
  def properties_from_fedora
    #object_rexml = REXML::Document.new(object_xml)
    #properties = {
    #     :pid => object_rexml.root.attributes["PID"],
    #     :state => object_rexml.root.elements["//foxml:property[@NAME='info:fedora/fedora-system:def/model#state']"].attributes["VALUE"],
    #     :create_date => object_rexml.root.elements["//foxml:property[@NAME='info:fedora/fedora-system:def/model#createdDate']"].attributes["VALUE"],
    #     :modified_date => object_rexml.root.elements["//foxml:property[@NAME='info:fedora/fedora-system:def/view#lastModifiedDate']"].attributes["VALUE"],
    #     :owner_id => object_rexml.root.elements['//foxml:property[@NAME="info:fedora/fedora-system:def/model#ownerId"]'].attributes['VALUE']
    #}
    #label_element = object_rexml.root.elements["//foxml:property[@NAME='info:fedora/fedora-system:def/model#label']"]
    #if profile_hash[:label]
    # properties.merge!({:label => label_element.attributes["VALUE"]})
    #end
    return profile
  end

  def create_date
    if attributes[:create_date] 
      return attributes[:create_date]
    elsif !new_object?
        properties_from_fedora[:create_date]
    else 
      return nil
    end
  end

  def modified_date
    if attributes[:modified_date] 
      return attributes[:modified_date]
    elsif !new_object?
        properties_from_fedora[:modified_date]
    else 
      return nil
    end
  end


  def pid
    self.attributes[:pid]
  end

  def pid=(new_pid)
    self.attributes.merge!({:pid => new_pid})
  end

  def state
    if attributes[:state] 
      return attributes[:state]
    elsif !new_object?
        properties_from_fedora[:state]
    else 
      return nil
    end
  end

  def state=(new_state)
    if ["I", "A", "D"].include? new_state
      self.attributes[:state]  = new_state
    else
      raise 'The object state of "' + new_state + '" is invalid. The allowed values for state are:  A (active), D (deleted), and I (inactive).'
    end
  end

  def label
    if attributes[:label] 
      return attributes[:label]
    elsif !new_object?
        properties_from_fedora[:label]
    else 
      return nil
    end
  end

  def label=(new_label)
    self.attributes[:label] = new_label
  end

  #  Get the object and read its @ownerId from the profile
  def owner_id
    if attributes[:owner_id] 
      return attributes[:owner_id]
    elsif !new_object?
        properties_from_fedora[:owner_id]
    else 
      return nil
    end
  end

  def owner_id=(new_owner_id)
    self.attributes.merge!({:ownerID => new_owner_id})
  end
  
  def profile
    # Use xmlsimple to slurp the attributes
    retrieved_profile = XmlSimple.xml_in(Fedora::Repository.instance.fetch_custom(self.pid, :profile))
    label = retrieved_profile["objLabel"].first unless retrieved_profile["objLabel"].first == {}
    profile_hash = Hash[:pid => retrieved_profile["pid"],
                          :owner_id => retrieved_profile["objOwnerId"].first,
                          :label => label,
                          :create_date =>  retrieved_profile["objCreateDate"].first,
                          :modified_date => retrieved_profile["objLastModDate"].first,
                          :methods_list_url => retrieved_profile["objDissIndexViewURL"].first,
                          :datastreams_list_url => retrieved_profile["objItemIndexViewURL"].first,
                          :state => retrieved_profile["objState"].first 
                        ]                           
  end

  def object_xml
    Fedora::Repository.instance.fetch_custom(pid, :objectXML)
  end
  
  def self.object_xml(pid=pid)
    Fedora::Repository.instance.fetch_custom(pid, :objectXML)
  end
  
  # See http://www.fedora.info/definitions/identifiers
  def uri
    "fedora:info/#{pid}"
  end
  
  # @returns the url of the object in Fedora, without the repository userinfo
  def url
    repo_url = Fedora::Repository.instance.fedora_url
    return "#{repo_url.scheme}://#{repo_url.host}:#{repo_url.port}#{repo_url.path}/objects/#{pid}"
  end
end  
