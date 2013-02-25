require 'spec_helper'

describe ActiveFedora::Auditable do

  before(:all) do
    class AuditableModel < ActiveFedora::Base
      include ActiveFedora::Auditable
    end
    path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'auditable.foxml.xml')
    pid = ActiveFedora::FixtureLoader.import_to_fedora(path)
    ActiveFedora::FixtureLoader.index(pid)
    @test_object = AuditableModel.find(pid)
  end
  after(:all) do
    @test_object.delete
  end
  it "should have the correct number of audit records" do
    @test_object.audit_trail.records.length.should == 3
  end
  it "should return all the data from each audit record" do
    record = @test_object.audit_trail.records.first
    record.id.should == "AUDREC1"
    record.process_type.should == "Fedora API-M"
    record.action.should == "addDatastream"
    record.component_id.should == "RELS-EXT"
    record.responsibility.should == "fedoraAdmin"
    record.date.should == "2013-02-25T16:43:06.219Z"
    record.justification.should == ""
  end
  
end
