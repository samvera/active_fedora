require File.join(File.dirname(__FILE__), '../spec_helper')

describe "initializing active-fedora in a rails 3 app" do
  it "should include ActiveFedora::Railtie" do
    begin
      ActiveFedora::Railtie
      railtie_loaded = true
    rescue NameError
      railtie_loaded = false
    end

    railtie_loaded.should be_true
      
  end
end
