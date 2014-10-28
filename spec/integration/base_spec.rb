require 'spec_helper'

describe "A base object with metadata" do
  before :each do
    class MockAFBaseRelationship < ActiveFedora::Base
      has_metadata 'foo', type: Hydra::ModsArticleDatastream
    end
  end
  after :each do
    Object.send(:remove_const, :MockAFBaseRelationship)
  end
  describe "a new document" do
    before do
      @obj = MockAFBaseRelationship.new

      @obj.foo.person = "bob"
      @obj.save
    end

    it "should save the datastream." do
      obj = ActiveFedora::Base.find(@obj.pid)
      expect(obj.foo).to_not be_new_record
      expect(obj.foo.person).to eq ['bob']
      person_field = ActiveFedora::SolrService.solr_name('foo__person', type: :string)
      solr_result = ActiveFedora::SolrService.query("{!raw f=id}#{@obj.pid}", :fl=>"id #{person_field}").first
      expect(solr_result).to eq("id"=>@obj.pid, person_field =>['bob'])
    end
  end

  describe "that already exists in the repo" do
    before do
      @release = MockAFBaseRelationship.create()
      @release.foo.person = "test foo content"
      @release.save
    end
    describe "and has been changed" do
      before do
        @release.foo.person = 'frank'
        @release.save!
      end
      it "should save the datastream." do
        expect(MockAFBaseRelationship.find(@release.pid).foo.person).to eq ['frank']
        person_field = ActiveFedora::SolrService.solr_name('foo__person', type: :string)
        expect(ActiveFedora::SolrService.query("id:\"#{@release.pid}\"", :fl=>"id #{person_field}").first).to eq("id"=>@release.pid, person_field =>['frank'])
      end
    end
  end

  describe '#reload' do
    before do
      @object = MockAFBaseRelationship.new
      @object.foo.person = 'bob'
      @object.save

      @object2 = @object.class.find(@object.pid)

      @object2.foo.person = 'dave'
      @object2.save
    end

    it 'should requery Fedora' do
      @object.reload
      expect(@object.foo.person).to eq ['dave']
    end

    it 'should raise an error if not persisted' do
      @object = MockAFBaseRelationship.new
      expect { @object.reload }.to raise_error(ActiveFedora::ObjectNotFoundError)
    end
  end
end

describe ActiveFedora::Base do
  describe "a saved object" do
    before do
      class Book < ActiveFedora::Base
        property :title, predicate: RDF::DC.title
      end
    end

    after do
      Object.send(:remove_const, :Book)
    end
    let!(:obj) { Book.create }

    after { obj.destroy unless obj.destroyed? }

    describe "errors" do
      subject { obj.errors }
      it { should be_empty }
    end

    describe "pid" do
      subject { obj.pid }
      it { should_not be_nil }
    end

    describe "that is updated" do
      before do
        # Give something to save
        obj.title = ['sample']#resource.insert([obj.rdf_subject, RDF::DC.title, 'sample'])
        # Make sure the modification time changes by at least 1 second
        sleep 1
      end

      it 'updates the modification time field in solr' do
        expect { obj.save }.to change {
          ActiveFedora::SolrService.query("id:\"#{obj.pid}\"").first['system_modified_dtsi']
        }
      end
    end

    describe "#create_date" do
      subject { obj.create_date }
      it { should_not be_nil }
    end

    describe "#modified_date" do
      subject { obj.modified_date }
      it { should_not be_nil }
    end

    describe "delete" do
      it "should delete the object from Fedora and Solr" do
        expect {
          obj.delete
        }.to change { ActiveFedora::Base.exists?(obj.pid) }.from(true).to(false)
      end
    end
  end
  

  describe "#exists?" do
    let(:obj) { ActiveFedora::Base.create } 
    it "should return true for objects that exist" do
      expect(ActiveFedora::Base.exists?(obj)).to be true
    end
    it "should return true for pids that exist" do
      expect(ActiveFedora::Base.exists?(obj.pid)).to be true
    end
    it "should return false for pids that don't exist" do
      expect(ActiveFedora::Base.exists?('test:missing_object')).to be false
    end
    it "should return false for nil" do
      expect(ActiveFedora::Base.exists?(nil)).to be false
    end
    it "should return false for false" do
      expect(ActiveFedora::Base.exists?(false)).to be false
    end
    it "should return false for empty" do
      expect(ActiveFedora::Base.exists?('')).to be false
    end
    context "when passed a hash of conditions" do
      let(:conditions) { {foo: "bar"} }
      context "and at least one object matches the conditions" do
        it "should return true" do
          allow(ActiveFedora::SolrService).to receive(:query) { [double("solr document")] }
          expect(ActiveFedora::Base.exists?(conditions)).to be true
        end
      end
      context "and no object matches the conditions" do
        it "should return false" do
          allow(ActiveFedora::SolrService).to receive(:query) { [] }
          expect(ActiveFedora::Base.exists?(conditions)).to be false
        end
      end
    end
  end
end
