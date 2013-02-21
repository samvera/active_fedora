require 'spec_helper'

describe ActiveFedora::Auditable do

  before do
    class AuditableModel < ActiveFedora::Base
      extends ActiveFedora::FixtureLoader
      include ActiveFedora::Auditable
    end
    @pid = "test:auditable"
    AuditableModel.import_to_fedora("#{Rails.root}/spec/fixtures/changeme155.xml", @pid)
    @test_object = AuditableModel.find(@pid)
  end
  after do
    @test_object.delete
  end
  it "should have the correct number of audit records" do
    @test_object.audit_trail.records.length.should == 14
  end
  it "should return all the data from each audit record" do
    record = @test_object.audit_trail.records.last
    record.id.should == "AUDREC14"
    record.process_type.should == "Fedora API-M"
    record.action.should == "addDatastream"
    record.component_id.should == "dublin_core"
    record.responsibility.should == "fedoraAdmin"
    record.date.should == "2008-11-19T18:18:49.003Z"
    record.justification.should == ""
  end
  
end
