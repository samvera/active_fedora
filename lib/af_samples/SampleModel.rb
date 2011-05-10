require "active-fedora"
require "af_samples"

# This is an example of an ActiveFedora Model
#
# Some of the datastream ids were chosen based on the Hydra modeling conventions.  You don't have to follow them in your work.  ActiveFedora itself has no notion of those conventions, but we do encourage you to use them.
#
# The Hydra conventions encourage you to have a datastream with this dsid whose contents are descriptive metadata like MODS or Dublin Core.  They especially encourage MODS.  
# The rightsMetadata datastream is also a convention provided by the Hydra Common Metadata "content model"
#
# For more info on the Hydra conventions, see the documentation on "Common Metadata content model" in https://wiki.duraspace.org/display/hydra/Hydra+content+models+and+disseminators
# Note that on the wiki, "content model" is often used to refer to Fedora CModels and/or abstract/notional models.  The Common Metadata content model is an example of this.
# The wiki includes a page that attempts to shed some light on the question of "What is a content model?" https://wiki.duraspace.org/display/hydra/Don't+call+it+a+'content+model'!
class SampleModel < ActiveFedora::Base
  
  #
  # DATASTREAMS
  #
  
  # This declares a datastream with Datastream ID (dsid) of "descMetadata"
  # The descMetadata datastream is bound to the Hydra::ModsArticleDatastream class that's defined in lib/af_samples
  # Any time you load a Fedora object using an instance of SampleModel, the instance will assume its descMetadata datastream conforms to the assumptions in Hydra::ModsArticleDatastream class
  has_metadata :name => "descMetadata", :type=> Hydra::ModsArticleDatastream
  
  # This declares a datastream with Datastream ID (dsid) of "rightsMetadata"
  # Like the descMetadata datastream, any time you load a Fedora object using an instance of SampleModel, the instance will assume its descMetadata datastream conforms to the assumptions in Hydra::RightsMetadataDatastream class
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadataDatastream
  
  # This is not part of the Hydra conventions
  # Adding an extra datastream called "extraMetadataForFun" that is bound to the Marpa::DcDatastream class
  has_metadata :name => "extraMetadataForFun", :type => Marpa::DcDatastream
  
  #
  # RELATIONSHIPS
  #
  
  # This is an example of how you can add a custom relationship to a model
  # This will allow you to call .derivations on instances of the model to get a list of all of the _outbound_ "hasDerivation" relationships in the RELS-EXT datastream
  relationship "derivations", :has_derivation

  # This will allow you to call .inspirations on instances of the model to get a list of all of the objects that assert "hasDerivation" relationships pointing at this object
  relationship "inspirations", :has_derivation, :inbound => true  
end