require "active-fedora"
require_relative '../hydra-mods_article_datastream.rb'
require_relative '../hydra-rights_metadata_datastream.rb'

# This Model is used to load & index the hydrangea:fixture_mods_article1 fixture for use in tests.
#
# See lib/samples/sample_thing.rb for a fuller, annotated example of an ActiveFedora Model
class HydrangeaArticle < ActiveFedora::Base
  
  has_metadata :name => "descMetadata", :type=> Hydra::ModsArticleDatastream  
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadataDatastream
  has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream

end
