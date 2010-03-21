require File.join( File.dirname(__FILE__), "..", "spec_helper" )

require 'active_fedora/solr_service'
require 'active_fedora/solr_mapper'

include ActiveFedora::SolrMapper

describe ActiveFedora::SolrMapper do
  
  after(:all) do
    # Revert to default mappings after running tests
    ActiveFedora::SolrService.load_mappings
  end
  
  describe ".solr_name" do
    it "should generate solr field names from settings in solr_mappings" do
      solr_name(:system_create, :date).should == :system_create_dt
    end
    it "should format the response based on the class of the input" do
      solr_name(:system_create, :date).should == :system_create_dt
      solr_name("system_create", :date).should == "system_create_dt"
    end
    it "should rely on whichever mappings have been loaded into the SolrService" do
      solr_name(:system_create, :date).should == :system_create_dt
      solr_name(:foo, :text).should == :foo_t
      ActiveFedora::SolrService.load_mappings(File.join(File.dirname(__FILE__), "..", "..", "config", "solr_mappings_af_0.1.yml"))
      solr_name(:system_create, :date).should == :system_create_date
      solr_name(:foo, :text).should == :foo_field
    end
  end
end