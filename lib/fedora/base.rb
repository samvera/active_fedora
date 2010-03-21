require 'xmlsimple'

class Hash
  #   {:q => 'test', :num => 5}.to_query # => 'q=test&num=5'
  #   let's avoid stomping on rails' version eh?
  def to_fedora_query
    self.collect { |key, value| "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}" }.sort * '&'
  end
  
  def self.from_xml(xml)
    XmlSimple.xml_in(xml, 'ForceArray' => false)
  end
end

class Fedora::BaseObject
  attr_accessor :attributes, :blob, :uri
  attr_reader :errors, :uri
  attr_writer :new_object
  
  # == Parameters
  # attrs<Hash>:: object attributes
  #-
  def initialize(attrs = {})
    @new_object = true
    @attributes = attrs || {}
    @errors = []
    @blob = attributes.delete(:blob)
    @repository = Fedora::Repository.instance
  end
  
  def [](key)
    @attributes[key]
  end
  
  def new_object?
    @new_object
  end
end
