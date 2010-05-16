#this class represents a MetadataDatastream, a special case of ActiveFedora::Datastream
require "hydra_libs/opinionated_mods_document"

class ModsDatastream < ActiveFedora::NokogiriDatastream
  self.xml_model = OpinionatedModsDocument
end