require File.join( File.dirname(__FILE__), "../spec_helper" )

# For testing Module-level methods like ActiveFedora.init

describe ActiveFedora do
  
  describe ".push_models_to_fedora" do
    it "should push the model definition for each of the ActiveFedora models into Fedora CModel objects" do
      pending
      # find all of the models 
      # create a cmodel for each model with the appropriate pid
      # push the model definition into the cmodel's datastream (ie. dsname: oral_history.rb vs dsname: ruby)
    end
  end
end