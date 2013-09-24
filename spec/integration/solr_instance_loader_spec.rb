require 'spec_helper'

require 'active_fedora'

describe ActiveFedora::SolrInstanceLoader do
  before(:all) do
    @test_object = ActiveFedora::Base.create
    @test_object2 = ActiveFedora::Base.create
  end

  let(:context) { ActiveFedora::Base }
  let(:pid) { nil }
  let(:solr_doc) { nil }
  let(:active_fedora_object) { ActiveFedora::Base.find(pid) }
  subject { ActiveFedora::SolrInstanceLoader.new(context, pid, solr_doc) }

  describe 'existing pid' do
    let(:pid) { @test_object.pid }
    describe 'without a solr document' do
      it 'it finds the SOLR document and casts into an AF::Base object' do
        expect(subject.object).to eq(active_fedora_object)
      end
    end
    describe 'with matching solr document' do
      let(:solr_doc) { ActiveFedora::Base.find_with_conditions(:id=>pid).first }
      it 'it casts the SOLR document and casts into an AF::Base object' do
        expect(subject.object).to eq(active_fedora_object)
      end
    end
    describe 'with a mismatching solr document' do
      let(:mismatching_pid) { @test_object2.pid }
      let(:solr_doc) { ActiveFedora::Base.find_with_conditions(:id=>mismatching_pid).first }
      it 'it raise ObjectNotFoundError' do
        expect {
          subject
        }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
  end
  describe 'missing pid' do
    let(:pid) { 'test:missing_pid' }
    describe 'without a solr document' do
      it 'it raise ObjectNotFoundError' do
        expect {
          subject.object
        }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
    describe 'with matching solr document' do
      let(:solr_doc) { ActiveFedora::Base.find_with_conditions(:id=>pid).first }
      it 'it raise ObjectNotFoundError' do
        expect {
          subject.object
        }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
    describe 'with a mismatching solr document' do
      let(:mismatching_pid) { @test_object2.pid }
      let(:solr_doc) { ActiveFedora::Base.find_with_conditions(:id=>mismatching_pid).first }
      it 'it raise ObjectNotFoundError' do
        expect {
          subject
        }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
  end
end
