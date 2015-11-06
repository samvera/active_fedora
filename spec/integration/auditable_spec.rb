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
  it 'should have the correct number of audit records' do
    expect(@test_object.audit_trail.records.length).to eq(1)
  end
  it 'should return all the data from each audit record' do
    record = @test_object.audit_trail.records.last
    expect(record.id).to eq('AUDREC1')
    expect(record.process_type).to eq('Fedora API-M')
    expect(record.action).to eq('addDatastream')
    expect(record.component_id).to eq('RELS-EXT')
    expect(record.responsibility).to eq('fedoraAdmin')
    expect(DateTime.parse(record.date)).to eq DateTime.parse(@test_object.modified_date)
    expect(record.justification).to eq('')
  end

end
