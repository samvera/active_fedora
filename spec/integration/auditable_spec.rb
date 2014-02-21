require 'spec_helper'

describe ActiveFedora::Auditable do

  before(:all) do
    class AuditableModel < ActiveFedora::Base
      include ActiveFedora::Auditable
    end
    @test_object = AuditableModel.create
    @test_object.reload
  end
  after(:all) do
    @test_object.delete
  end
  it "should have the correct number of audit records" do
    @test_object.audit_trail.records.length.should == 1
  end
  it "should return all the data from each audit record" do
    record = @test_object.audit_trail.records.last
    record.id.should == "AUDREC1"
    record.process_type.should == "Fedora API-M"
    record.action.should == "addDatastream"
    record.component_id.should == "RELS-EXT"
    record.responsibility.should == "fedoraAdmin"
    expect(DateTime.parse(record.date)).to eq DateTime.parse(@test_object.modified_date)
    record.justification.should == ""
  end
  
end
